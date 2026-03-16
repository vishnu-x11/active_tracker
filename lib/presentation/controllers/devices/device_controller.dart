import 'package:get/get.dart';

class HealthDevice {
  final String id;
  final String name;
  final String type; // 'Watch', 'Scale', 'HRM'
  final bool isConnected;
  final String batteryLevel;

  HealthDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
    this.batteryLevel = '100%',
  });
}

class DeviceController extends GetxController {
  final devices = <HealthDevice>[].obs;
  final isScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadConnectedDevices();
  }

  void loadConnectedDevices() {
    // Mock connected devices
    devices.value = [
      HealthDevice(id: '1', name: 'Active Health Watch v1', type: 'Watch', isConnected: true, batteryLevel: '85%'),
    ];
  }

  Future<void> scanForDevices() async {
    isScanning.value = true;
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock discovered devices
    final discovered = [
      HealthDevice(id: '2', name: 'Smart Scale Pro', type: 'Scale'),
      HealthDevice(id: '3', name: 'Chest Strap HRM', type: 'HRM'),
    ];
    
    for (var device in discovered) {
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
      }
    }
    
    isScanning.value = false;
  }

  void connectDevice(String id) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final d = devices[index];
      devices[index] = HealthDevice(
        id: d.id,
        name: d.name,
        type: d.type,
        isConnected: true,
        batteryLevel: '95%',
      );
      Get.snackbar('Connected', '${d.name} is now active.');
    }
  }
}
