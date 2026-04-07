# OGARM - Open-Source 6-DOF Robotic Arm

OGARM is a high-performance, open-source robotic arm built on the ESP32 platform. It combines robust hardware with a feature-rich mobile application, enabling precise control, autonomous recording, and playback of complex movements.

## 🚀 Features

- **6-DOF Articulated Arm**: Full 6-axis control for versatile manipulation tasks.
- **ESP32-Powered**: Utilizes the powerful ESP32 microcontroller for high-speed processing and Wi-Fi connectivity.
- **Mobile App Control**: Dedicated Flutter application for intuitive control and monitoring.
- **Autonomous Recording**: Record and store complex movement sequences directly on the device.
- **Playback & Looping**: Execute recorded sequences with adjustable speed and loop functionality.
- **Real-time Telemetry**: Monitor arm temperature, heap memory, and uptime.
- **Emergency Stop**: Instantaneous safety override for all servos.
- **Cross-Platform**: Built with Flutter, compatible with Android and iOS.

## 🛠️ Hardware Requirements

- **Microcontroller**: ESP32 (DevKitC recommended)
- **Servos**: 6 x MG996R or similar high-torque servos
- **Power Supply**: 5V 4A+ external power supply for servos
- **OLED Display**: 0.96" I2C OLED (SSD1306)
- **Wiring**: Jumper wires, breadboard (optional)

## 🔌 Wiring Diagram

| ESP32 Pin | Servo Pin | OLED Pin |
|-----------|-----------|----------|
| 3V3       | VCC       | 3.3V     |
| GND       | GND       | GND      |
| D1 (GPIO5)| Signal    | D1 (SCL) |
| D2 (GPIO4)| Signal    | D2 (SDA) |

**Note**: Servos must be powered by an external 5V supply, not the ESP32's 3.3V rail.

## 📡 ESP32 Firmware

The firmware creates a Wi-Fi Access Point for direct device connection.

**Network Details:**
- **SSID**: `OGARM`
- **Password**: `iloveogdeck`
- **IP Address**: `192.168.4.1`

### Arduino Code
```cpp
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WebServer.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ... (Full code available in firmware/ogarm_esp32s/ogarm_esp32s.ino) ...
```

## 📱 Flutter Application

The mobile app provides a comprehensive interface for controlling the robotic arm.

### Key Features
- **Dashboard**: Real-time telemetry and connection status.
- **Manual Control**: Individual sliders for each of the 6 servos.
- **Sequence Recorder**: Record, name, and save movement sequences.
- **Sequence Player**: Playback sequences with speed control and looping.
- **Emergency Stop**: One-tap safety stop.
- **Settings**: Configure IP address and connection settings.

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ogarm
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
ogarm/
├── firmware/                # ESP32 Firmware
│   └── ogarm_esp32s/
│       └── ogarm_esp32s.ino
├── lib/                     # Flutter Application
│   ├── main.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── manual_control_screen.dart
│   │   ├── sequences_screen.dart
│   │   ├── settings_screen.dart
│   │   └── sequence_editor_screen.dart
│   ├── services/
│   │   ├── robot_service.dart
│   │   └── sequence_service.dart
│   └── widgets/
│       ├── servo_slider.dart
│       ├── sequence_card.dart
│       └── telemetry_display.dart
├── pubspec.yaml
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Built By

- **Grobotics team**

## 📞 Support

For issues or questions, please open an issue in the repository.
