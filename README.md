# Posture Correction Device

Posture Correction Device is a wearable prototype designed to monitor and improve user body posture. The system is built using an **ESP32-C3**, **MPU6050**, and **flex sensor** to detect posture conditions and provide vibration feedback when poor posture is detected.

The device also supports **Bluetooth Low Energy (BLE)** communication to connect with a mobile application developed using **Flutter**. Through the mobile app, users can monitor posture data in real time and control the vibration motor feedback.

## Features

- Real-time posture monitoring using flex sensor data
- Motion data reading from MPU6050 accelerometer and gyroscope
- Posture classification into Good, Warning, and Bad conditions
- RGB LED indicator for posture status
- Vibration feedback when incorrect posture is detected
- BLE communication with Flutter mobile application
- Real-time data transmission from ESP32-C3 to mobile app
- Vibration motor control through BLE command

## Hardware Components

| Component | Description |
|---|---|
| ESP32-C3 | Main microcontroller |
| MPU6050 | Accelerometer and gyroscope sensor |
| Flex Sensor | Sensor for detecting body bending/posture changes |
| Vibration Motor | Haptic feedback for posture warning |
| RGB LED | Visual indicator for posture status |
| Li-ion Battery | Power source |
| TP4056 | Battery charging module |
| MT3608 | Step-up converter module |
| Switch | Power ON/OFF control |
| Jumper Cable | Component connection |

## Software and Tools

| Software / Library | Description |
|---|---|
| Arduino IDE | Firmware development for ESP32-C3 |
| Flutter | Mobile application development |
| BLE Library | Bluetooth Low Energy communication |
| MPU6050 Library | Sensor data reading |
| Wire Library | I2C communication |

## Pin Configuration

| Component | ESP32-C3 Pin |
|---|---|
| Flex Sensor | GPIO 2 |
| Vibration Motor | GPIO 3 |
| RGB LED - Red | GPIO 4 |
| RGB LED - Green | GPIO 7 |
| RGB LED - Blue | GPIO 10 |
| MPU6050 SDA | GPIO 5 |
| MPU6050 SCL | GPIO 6 |

> Note: The vibration motor is recommended to be connected through a transistor or motor driver circuit to protect the ESP32-C3 pin.

## System Overview

The device reads posture-related data from the flex sensor and MPU6050. The flex sensor is used as the main input for posture classification, while the MPU6050 provides motion data that can be sent to the mobile application for monitoring.

The system classifies posture into three conditions:

| Status Code | Condition | Indicator | Motor Feedback |
|---|---|---|---|
| 0 | Good Posture | Green LED | OFF |
| 1 | Warning Posture | Yellow LED | Low vibration |
| 2 | Bad Posture | Red LED | Strong vibration |

When the flex sensor value exceeds the warning or bad posture threshold, the device activates the vibration motor as feedback. The RGB LED also changes color based on the detected posture condition.

## Posture Threshold

The firmware uses predefined flex sensor threshold values:

```cpp
int flexNormal = 3147;
int flexWarning = 3180;
int flexBad = 3270;
```

Posture classification logic:

- Flex value below `flexWarning` = Good Posture
- Flex value between `flexWarning` and `flexBad` = Warning Posture
- Flex value above `flexBad` = Bad Posture

## BLE Communication

The ESP32-C3 acts as a BLE server with the device name:

```text
Posture Monitor
```

### BLE UUID

| UUID Type | Value |
|---|---|
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| RX Characteristic UUID | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| TX Characteristic UUID | `beb5483f-36e1-4688-b7f5-ea07361b26a8` |

### Data Sent to Mobile App

The ESP32-C3 sends posture data every 200 ms using BLE notification.

Data format:

```text
flexValue,ay,postureStatus
```

Example:

```text
3150,-1240,0
```

Description:

| Data | Description |
|---|---|
| flexValue | Analog reading from flex sensor |
| ay | Y-axis accelerometer value from MPU6050 |
| postureStatus | Posture condition code: 0 Good, 1 Warning, 2 Bad |

## BLE Commands from Mobile App

The Flutter mobile application can send commands to the ESP32-C3 through the RX characteristic.

| Command | Function |
|---|---|
| `MOTOR_ON` | Enable vibration motor feedback |
| `MOTOR_OFF` | Disable vibration motor feedback |

## Mobile Application

The mobile application is developed using **Flutter** and communicates with the ESP32-C3 using Bluetooth Low Energy.

Main functions of the application:

- Connect to ESP32-C3 through BLE
- Display real-time flex sensor data
- Display MPU6050 Y-axis data
- Show posture status
- Enable or disable vibration feedback

## How It Works

1. The ESP32-C3 reads data from the flex sensor and MPU6050.
2. The flex sensor value is compared with predefined posture thresholds.
3. The device determines whether the posture is Good, Warning, or Bad.
4. The RGB LED changes color based on the posture condition.
5. The vibration motor provides feedback when the posture is not ideal.
6. The posture data is sent to the Flutter mobile app through BLE.
7. The mobile app displays posture data in real time and can send control commands back to the device.

This project is intended for educational and research purposes.