#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <Servo.h>

// --- 7 SERVO CONFIGURATION ---
// Servo 1 (Gripper) is on D1. 
// Servos 2-7 (Arm Joints) are on D3, D4, D5, D6, D7, D8
int servoPins[7] = {D1, D3, D4, D5, D6, D7, D8};
Servo s[7];

// All 7 motors start at 90 degrees (Rest Position)
float currentPos[7] = {90, 90, 90, 90, 90, 90, 90};
int targetPos[7]    = {90, 90, 90, 90, 90, 90, 90};

// --- RECORDING SYSTEM ---
#define MAX_STEPS 250
int recordData[MAX_STEPS][7];
int stepCount = 0, playIndex = 0;
bool recording = false, playing = false;
unsigned long lastRecTime = 0, playTimer = 0;

ESP8266WebServer server(80);

// --- APP CORS HANDLER ---
// Ensures the mobile app is allowed to communicate with the ESP8266
void sendAppResponse(int code, String contentType, String content) {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Origin, Content-Type, Accept");
  server.send(code, contentType, content);
}

// --- WEB DASHBOARD ---
String getHTML() {
  String h = "<!DOCTYPE html><html><head>";
  h += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  h += "<style>body{font-family:sans-serif; text-align:center; background:#1a1a1a; color:white;}";
  h += ".btn{padding:15px 25px; margin:10px; border-radius:10px; border:none; font-weight:bold; cursor:pointer;}";
  h += ".rec{background:#ff4757; color:white;} .play{background:#2ed573; color:white;} .stop{background:#57606f; color:white;}";
  h += "input[type=range]{width:80%; height:20px; margin:10px 0;}</style></head><body>";
  h += "<h1>Grobotics 7-Axis Control</h1>";
  
  // Control Buttons
  h += "<button class='btn rec' onclick=\"fetch('/record')\">RECORD</button>";
  h += "<button class='btn play' onclick=\"fetch('/play')\">PLAYBACK</button>";
  h += "<button class='btn stop' onclick=\"fetch('/stop')\">STOP</button><hr>";
  
  // 1. Gripper Slider (Locked to 0-90)
  h += "<h3>1. Gripper (D1) [0-90&deg;]</h3>";
  h += "<input type='range' min='0' max='90' value='90' oninput=\"fetch('/set?servo=1&value='+this.value)\"><hr>";
  
  // 2. Arm Sliders (0-180)
  for(int i=2; i<=7; i++) {
    h += "<h3>Servo " + String(i) + "</h3>";
    h += "<input type='range' min='0' max='180' value='90' oninput=\"fetch('/set?servo=" + String(i) + "&value='+this.value)\">";
  }
  
  h += "<p>Connected to OGARM AP</p></body></html>";
  return h;
}

void setup() {
  Serial.begin(115200);

  // 1. Force Access Point mode only (prevents crashing if no internet)
  WiFi.mode(WIFI_AP);

  // 2. Explicitly configure IP to 192.168.4.1 for App compatibility
  IPAddress local_IP(192, 168, 4, 1);
  IPAddress gateway(192, 168, 4, 1);
  IPAddress subnet(255, 255, 255, 0);
  WiFi.softAPConfig(local_IP, gateway, subnet);
  
  // 3. Start AP
  WiFi.softAP("OGARM", "iloveogdeck");

  // 4. Attach all 7 servos with 180-degree pulse fix
  for(int i=0; i<7; i++){
    s[i].attach(servoPins[i], 500, 2500);
    s[i].write(90); // Default to 90 degrees rest position
  }

  // --- SERVER ROUTES ---
  
  // Handle Preflight OPTIONS for mobile apps
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      server.sendHeader("Access-Control-Allow-Headers", "Origin, Content-Type, Accept");
      server.send(204); 
    } else {
      server.send(404, "text/plain", "Not found");
    }
  });

  server.on("/", [](){ sendAppResponse(200, "text/html", getHTML()); });
  
  server.on("/set", [](){
    int i = server.arg("servo").toInt() - 1; // Converts Servo 1-7 to Index 0-6
    int v = server.arg("value").toInt();
    
    // Safety constraint: Enforce 0-90 for Gripper (Index 0), 0-180 for others
    if(i == 0) {
      v = constrain(v, 0, 90);
    } else if (i > 0 && i < 7) {
      v = constrain(v, 0, 180);
    }
    
    if(i >= 0 && i < 7) targetPos[i] = v;
    sendAppResponse(200, "text/plain",
    "OK");
  });
  
  server.on("/record", [](){ recording=true; playing=false; stepCount=0; sendAppResponse(200, "text/plain", "REC"); });
  server.on("/play", [](){ playing=true; recording=false; playIndex=0; sendAppResponse(200, "text/plain", "PLAY"); });
  server.on("/stop", [](){ recording=false; playing=false; sendAppResponse(200, "text/plain", "STOP"); });

  server.on("/telemetry", [](){
    String json = "{";
    json += "\"status\": \"" + String(recording ? "RECORDING" : (playing ? "PLAYING" : "IDLE")) + "\",";
    json += "\"steps\": " + String(stepCount) + ",";
    json += "\"heap\": " + String(ESP.getFreeHeap());
    json += "}";
    sendAppResponse(200, "application/json", json);
  });

  server.begin();
}

void loop() {
  server.handleClient();
  unsigned long now = millis();

  // 1. Smooth Servo Engine (Handles all 7 motors)
  static unsigned long lastMove = 0;
  if(now - lastMove > 20){
    lastMove = now;
    for(int i = 0; i < 7; i++){
      float diff = targetPos[i] - currentPos[i];
      if(abs(diff) > 0.5){
        currentPos[i] += diff * 0.15; // Speed multiplier for smooth gliding
        s[i].writeMicroseconds(map((int)currentPos[i], 0, 180, 500, 2500));
      }
    }
  }

  // 2. Recording Sync (Captures 7 data points per step)
  if(recording && (now - lastRecTime > 150)){
    lastRecTime = now;
    if(stepCount < MAX_STEPS){
      for(int i=0; i<7; i++) recordData[stepCount][i] = targetPos[i];
      stepCount++;
    }
  }
  
  // 3. Playback Sync (Plays back 7 data points per step)
  if(playing && (now - playTimer > 250)){
    playTimer = now;
    if(playIndex < stepCount){
      for(int i=0; i<7; i++) targetPos[i] = recordData[playIndex][i];
      playIndex++;
    } else { playing = false; }
  }
}