import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/posture_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PostureProvider>(context);
    final isConnected = provider.connectionState == BluetoothConnectionState.connected;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Device Settings",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              

              // Motor Toggle Settings
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.vibration_rounded, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Vibration Motor", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(provider.motorEnabled ? "Motor is ON" : "Motor is OFF", style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: provider.motorEnabled,
                      onChanged: isConnected ? (value) => provider.toggleMotor() : null,
                      activeColor: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Connection Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? const Color(0xFF10B981).withOpacity(0.1) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isConnected 
                        ? const Color(0xFF10B981).withOpacity(0.3) 
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? "Connected to Monitor" : "Disconnected",
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected ? "Ready to track posture" : "Please pair your device",
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected)
                      GestureDetector(
                        onTap: () => provider.disconnect(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Disconnect", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Scan Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isScanning ? null : () => provider.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: provider.isScanning ? 0 : 8,
                    shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (provider.isScanning) 
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      else 
                        const Icon(Icons.radar_rounded),
                      const SizedBox(width: 12),
                      Text(
                        provider.isScanning ? "Scanning for devices..." : "Scan for Devices",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Device List
              const Text("Available Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: provider.scanResults.isEmpty 
                  ? const Center(child: Text("No devices found", style: TextStyle(color: Color(0xFF6B7280))))
                  : ListView.builder(
                  itemCount: provider.scanResults.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final result = provider.scanResults[index];
                    if (result.device.advName.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(result.device.advName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                        trailing: ElevatedButton(
                          onPressed: () => provider.connect(result.device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Pair"),
                        ),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
