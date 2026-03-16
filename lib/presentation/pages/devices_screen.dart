import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/devices/device_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class DevicesScreen extends GetView<DeviceController> {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearables & Devices'),
        actions: [
          Obx(() => IconButton(
            icon: controller.isScanning.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh),
            onPressed: controller.isScanning.value ? null : () => controller.scanForDevices(),
          )),
        ],
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.all(AppPadding.md),
        itemCount: controller.devices.length,
        itemBuilder: (context, index) {
          final device = controller.devices[index];
          return _buildDeviceCard(device);
        },
      )),
    );
  }

  Widget _buildDeviceCard(HealthDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: device.isConnected ? AppTheme.primary.withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppPadding.md),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: device.isConnected ? AppTheme.primary.withOpacity(0.1) : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: device.isConnected ? AppTheme.primary : Colors.grey,
          ),
        ),
        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.type, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (device.isConnected)
              Row(
                children: [
                  const Icon(Icons.battery_3_bar, size: 12, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text(device.batteryLevel, style: const TextStyle(color: AppTheme.success, fontSize: 10)),
                ],
              ),
          ],
        ),
        trailing: device.isConnected 
          ? const Text('CONNECTED', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold))
          : ElevatedButton(
              onPressed: () => controller.connectDevice(device.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('PAIR', style: TextStyle(fontSize: 10)),
            ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Watch': return Icons.watch;
      case 'Scale': return Icons.monitor_weight;
      case 'HRM': return Icons.favorite;
      default: return Icons.bluetooth;
    }
  }
}
