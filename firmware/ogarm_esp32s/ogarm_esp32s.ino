h += "<button class='btn rec' onclick=\"fetch('/record')\">RECORD</button>";
  h += "<button class='btn play' onclick=\"fetch('/play')\">PLAYBACK</button>";
  h += "<button class='btn stop' onclick=\"fetch('/stop')\">STOP</button><hr>";
  for(int i=1; i<=6; i++) {
    h += "<h3>Servo " + String(i) + "</h3>";
    h += "<input type='range' min='0' max='180' value='90' oninput=\"fetch('/set?servo=" + String(i) + "&value='+this.value)\">";
  }
  h += "<p>Connected to Grobotics NodeMCU</p></body></html>";
  return h;
}

void setup() {
  Wire.begin(D2, D1);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  runBootSequence();

  // 1. Force Access Point mode only (prevents STA mode hangs)
  WiFi.mode(WIFI_AP);

  // 2. Explicitly configure IP to 192.168.4.1
  IPAddress local_IP(192, 168, 4, 1);
  IPAddress gateway(192, 168, 4, 1);
  IPAddress subnet(255, 255, 255, 0);
  WiFi.softAPConfig(local_IP, gateway, subnet);
  
  // 3. Start AP with correct name and password
  WiFi.softAP("OGARM", "iloveogdeck");

  for(int i=0; i<6; i++){
    s[i].attach(servoPins[i], 500, 2500);
    s[i].write(90);
  }

  // --- ROUTES (Now using App Response for CORS) ---
  
  // Handle Preflight OPTIONS requests for mobile apps
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      server.sendHeader("Access-Control-Allow-Headers", "Origin, Content-Type, Accept");
      server.send(204); // "No Content" OK response
    } else {
      server.send(404, "text/plain", "Not found");
    }
  });

  server.on("/", [](){ sendAppResponse(200, "text/html", getHTML()); });
  
  server.on("/set", [](){
    int i = server.arg("servo").toInt()-1;
    int v = server.arg("value").toInt();
    if(i>=0 && i<6) targetPos[i] = v;
    sendAppResponse(200, "text/plain", "OK");
  });
  
  server.on("/record", [](){ recording=true; playing=false; stepCount=0; sendAppResponse(200, "text/plain", "REC"); });
  server.on("/play", [](){ playing=true; recording=false; playIndex=0; sendAppResponse(200, "text/plain", "PLAY"); });
  server.on("/stop", [](){ recording=false; playing=false; sendAppResponse(200, "text/plain", "STOP"); });

  server.on("/telemetry", [](){
    String json = "{";
    json += "\"temp\": 0,";
    json += "\"heap\": " + String(ESP.getFreeHeap()) + ",";
    json += "\"uptime\": " + String(millis() / 1000);
    json += "}";
    sendAppResponse(200, "application/json", json);
  });

  server.begin();
}

void loop() {
  server.handleClient();
  unsigned long now = millis();

  // 1. Servo Engine
  static unsigned long lastMove = 0;
  if(now - lastMove > 20){
    lastMove = now;
    for(int i = 0; i < 6; i++){
      float diff = targetPos[i] - currentPos[i];
      if(abs(diff) > 0.5){
        currentPos[i] += diff * 0.15;
        s[i].writeMicroseconds(map((int)currentPos[i], 0, 180, 500, 2500));
      }
    }
  }

  // 2. Logic Sync
  if(recording && (now - lastRecTime > 150)){
    lastRecTime = now;
    if(stepCount < MAX_STEPS){
      for(int i=0; i<6; i++) recordData[stepCount][i] = targetPos[i];
      stepCount++;
    }
  }
  if(playing && (now - playTimer > 250)){
    playTimer = now;
    if(playIndex < stepCount){
      for(int i=0; i<6; i++) targetPos[i] = recordData[playIndex][i];
      playIndex++;
    } else { playing = false; }
  }

  // 3. OLED Sync
  static unsigned long oledUpdate = 0;
  static bool blink = false;
  if(now - oledUpdate > 120) {
    oledUpdate = now;
    display.clearDisplay();
    
    String modeStr = "IDLE";
    if(recording) modeStr = "REC";
    if(playing) modeStr = "PLAY";

    if(!blink && random(0, 40) == 10) blink = true; else blink = false;

    drawEyes(blink, modeStr);

    display.setTextSize(1);
    display.setCursor(10, 38);
    display.print("Welcome Grobotics");
    display.setCursor(0, 50);
    display.print("IP: "); display.print(WiFi.softAPIP().toString());
    display.setCursor(0, 58);
    display.print("MODE: "); display.print(modeStr);
    if(playing) display.fillRect(70, 60, map(playIndex, 0, stepCount, 0, 50), 3, WHITE);
    if(recording) { display.setCursor(85, 58); display.print("S:"); display.print(stepCount); }

    display.display();
  }
}