import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../models/posture_data.dart';

class PostureProvider with ChangeNotifier {
  BleService? _bleService;
  // Storage
  final StorageService _storageService = StorageService();

  // BLE State
  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  // Posture State
  int flexValue = 0;
  int flexBaseline = 3147; // Hardcoded default upright baseline
  int leaningAngle = 0;
  double _smoothedAngle = 0.0;
  int postureStatus = 0; // 0: Good, 1: Warning, 2: Bad
  
  // Stats
  int totalSittingSeconds = 0;
  int badPostureSeconds = 0;
  int warningPostureSeconds = 0;
  int goodPostureSeconds = 0;

  // History
  List<PostureData> history = [];

  // Settings
  bool motorEnabled = true;

  Timer? _sessionTimer;
  Timer? _badPostureTimer;

  PostureProvider() {
    _loadHistory();
    
    _bleService = BleService(
      onDataReceived: _handleDataReceived,
      onConnectionChanged: _handleConnectionChanged,
    );

    // Start a timer to track total sitting time if connected
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (connectionState == BluetoothConnectionState.connected) {
        totalSittingSeconds++;
        if (postureStatus == 0) goodPostureSeconds++;
        if (postureStatus == 1) warningPostureSeconds++;
        if (postureStatus == 2) badPostureSeconds++;

        // Trigger notification if bad posture is sustained for 5 seconds
        if (postureStatus == 2) {
           _badPostureTimer ??= Timer(const Duration(seconds: 5), () {
             // Hardware handles the vibration now, no push notification needed.
            _badPostureTimer = null;
          });
        } else {
          _badPostureTimer?.cancel();
          _badPostureTimer = null;
        }

        notifyListeners();
      }
    });

    // Save history periodically
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (history.isNotEmpty) {
        _storageService.saveHistory(history);
      }
    });
  }


  Future<void> _loadHistory() async {
    history = await _storageService.loadHistory();
    notifyListeners();
  }

  void _handleDataReceived(String data) {
    // Expected format: flexValue,ay,postureStatus
    try {
      final parts = data.split(',');
      if (parts.length == 3) {
        flexValue = int.parse(parts[0]);
        int rawAy = int.parse(parts[1]);
        
        // 1. Calculate angle from MPU6050 (approx -16384 to 16384 -> -90 to 90 degrees)
        double mpuAngle = (rawAy / 16384.0).clamp(-1.0, 1.0) * 90.0;
        
        // 2. Calculate angle from Flex Sensor using hardcoded baseline (3147)
        // Upright = ~3147. Bad posture bend = ~3277. Difference = 130.
        // A realistic "bad" bend is around 45 degrees, not 90.
        double flexAngle = ((flexValue - flexBaseline) / 130.0) * 45.0;
        
        // Allow slightly negative angles if leaning back, but clamp to sensible limits
        flexAngle = flexAngle.clamp(-15.0, 90.0);

        // 3. Use 100% flex sensor (ignore MPU)
        double combinedAngle = flexAngle;

        // 4. Apply Exponential Moving Average (EMA) filter to stop it from jumping wildly
        _smoothedAngle = (_smoothedAngle * 0.9) + (combinedAngle * 0.1);
        leaningAngle = _smoothedAngle.round();
        
        // Calculate posture status locally based on the new angle
        if (leaningAngle < 12) {
          postureStatus = 0; // Good (under 12 degrees)
        } else if (leaningAngle < 40) {
          postureStatus = 1; // Warning (12 to 39 degrees)
        } else {
          postureStatus = 2; // Bad (40+ degrees)
        }
        
        // Save to history list
        history.add(PostureData(
          timestamp: DateTime.now(),
          flexValue: flexValue,
          leaningAngle: leaningAngle,
          postureStatus: postureStatus,
          mpuAngle: mpuAngle,
        ));
        
        notifyListeners();
      }
    } catch (e) {
      print("Error parsing data: $e");
    }
  }

  void _handleConnectionChanged(BluetoothConnectionState state) {
    connectionState = state;
    notifyListeners();
  }

  Future<void> startScan() async {
    isScanning = true;
    notifyListeners();
    
    _bleService?.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
    
    await _bleService?.startScan();
    
    isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _bleService?.connectToDevice(device);
  }

  Future<void> disconnect() async {
    await _bleService?.disconnect();
  }

  Future<void> toggleMotor() async {
    motorEnabled = !motorEnabled;
    await _bleService?.sendCommand(motorEnabled ? "MOTOR_ON" : "MOTOR_OFF");
    notifyListeners();
  }

  Future<String> exportData() async {
    if (history.isEmpty) return "No data to export";
    try {
      final directory = await getTemporaryDirectory();
      
      final File file = File('${directory.path}/posture_history.csv');
      
      String csvData = "Timestamp,Flex Value,Leaning Angle,Posture Status,MPU Angle\n";
      for (var data in history) {
        csvData += "${data.timestamp.toIso8601String()},${data.flexValue},${data.leaningAngle},${data.postureStatus},${data.mpuAngle.toStringAsFixed(2)}\n";
      }
      
      await file.writeAsString(csvData);
      
      // Open share/save dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Posture Monitor History Data',
        subject: 'posture_history.csv'
      );
      
      return "Choose where to save the file.";
    } catch (e) {
      return "Failed to save: $e";
    }
  }

  Future<void> clearHistory() async {
    history.clear();
    await _storageService.saveHistory([]);
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _badPostureTimer?.cancel();
    _bleService?.dispose();
    super.dispose();
  }
}
