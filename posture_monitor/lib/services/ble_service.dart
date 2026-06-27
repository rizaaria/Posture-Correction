import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID_RX = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String CHARACTERISTIC_UUID_TX = "beb5483f-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final Function(String) onDataReceived;
  final Function(BluetoothConnectionState) onConnectionChanged;

  BleService({
    required this.onDataReceived,
    required this.onConnectionChanged,
  });

  Future<void> startScan() async {
    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    connectedDevice = device;

    _connectionSubscription = device.connectionState.listen((state) {
      onConnectionChanged(state);
      if (state == BluetoothConnectionState.disconnected) {
        _notifySubscription?.cancel();
        txCharacteristic = null;
        rxCharacteristic = null;
      }
    });

    await device.connect(license: License.nonprofit);
    await _discoverServices();
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString() == CHARACTERISTIC_UUID_TX) {
            txCharacteristic = c;
            await c.setNotifyValue(true);
            _notifySubscription = c.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String data = String.fromCharCodes(value);
                onDataReceived(data);
              }
            });
          }
          if (c.uuid.toString() == CHARACTERISTIC_UUID_RX) {
            rxCharacteristic = c;
          }
        }
      }
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }

  Future<void> sendCommand(String command) async {
    if (rxCharacteristic != null) {
      await rxCharacteristic!.write(command.codeUnits, withoutResponse: false);
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    disconnect();
  }
}
