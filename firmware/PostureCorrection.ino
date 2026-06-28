#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <MPU6050.h>
#include <Wire.h>

MPU6050 mpu;

// ================= PIN =================
#define FLEX_PIN 2

#define MOTOR_PIN 3

#define RED_PIN 4
#define GREEN_PIN 7
#define BLUE_PIN 10

// ============= THRESHOLD =============
int flexNormal = 3147;  // disamakan dengan aplikasi (Plug and Play)
int flexWarning = 3180; // berdasarkan data warning.csv
int flexBad = 3270;     // berdasarkan data bungkuk.csv

// ================= BLE =================
BLEServer *pServer = NULL;
BLECharacteristic *pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_RX "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_UUID_TX "beb5483f-36e1-4688-b7f5-ea07361b26a8"

bool motorEnabled = true;

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) { deviceConnected = true; };

  void onDisconnect(BLEServer *pServer) { deviceConnected = false; }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue().c_str();
    if (rxValue.length() > 0) {
      Serial.print("Received Value: ");
      for (int i = 0; i < rxValue.length(); i++) {
        Serial.print(rxValue[i]);
      }
      Serial.println();

      if (rxValue == "MOTOR_ON") {
        motorEnabled = true;
      } else if (rxValue == "MOTOR_OFF") {
        motorEnabled = false;
      } else if (rxValue == "CALIBRATE") {
        flexNormal = analogRead(FLEX_PIN);
        flexWarning = flexNormal + 400;
        flexBad = flexNormal + 800;
        Serial.println("Calibrated!");
      }
    }
  }
};

// ======================================

void setRGB(bool r, bool g, bool b) {
  digitalWrite(RED_PIN, r);
  digitalWrite(GREEN_PIN, g);
  digitalWrite(BLUE_PIN, b);
}

void setup() {
  Serial.begin(115200);

  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);

  pinMode(MOTOR_PIN, OUTPUT);

  // Setup I2C untuk ESP32-C3
  Wire.begin(5, 6);

  mpu.initialize();

  if (!mpu.testConnection()) {
    Serial.println("MPU6050 gagal terhubung!");
  } else {
    Serial.println("MPU6050 terhubung");
  }

  // Initialize BLE
  BLEDevice::init("Posture Monitor");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pCharacteristicRx = pService->createCharacteristic(
      CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE);
  pCharacteristicRx->setCallbacks(new MyCallbacks());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(
      0x0); // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {
  int16_t ax, ay, az;
  int16_t gx, gy, gz;

  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  int flexValue = analogRead(FLEX_PIN);

  // Debug via Serial
  Serial.print("Flex: ");
  Serial.print(flexValue);
  Serial.print(" | AY: ");
  Serial.println(ay);

  int postureStatus = 0; // 0: Good, 1: Warning, 2: Bad

  // ==================
  // KATEGORI POSTUR
  // ==================
  if (flexValue < flexWarning) {
    // Normal
    setRGB(0, 1, 0);
    analogWrite(MOTOR_PIN, 0);
    postureStatus = 0;
  } else if (flexValue < flexBad) {
    // Sedikit membungkuk
    setRGB(1, 1, 0);
    if (motorEnabled)
      analogWrite(MOTOR_PIN, 100);
    else
      analogWrite(MOTOR_PIN, 0);
    postureStatus = 1;
  } else {
    // Membungkuk parah
    setRGB(1, 0, 0);
    if (motorEnabled)
      analogWrite(MOTOR_PIN, 255);
    else
      analogWrite(MOTOR_PIN, 0);
    postureStatus = 2;
  }

  // Send BLE notification
  if (deviceConnected) {
    // format data: flexValue,ay,postureStatus
    String txString =
        String(flexValue) + "," + String(ay) + "," + String(postureStatus);
    pCharacteristic->setValue(txString.c_str());
    pCharacteristic->notify();
  }

  // Handle disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }

  // Handle connecting
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  delay(200); // Send data every 200ms
}