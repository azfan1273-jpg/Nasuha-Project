import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';

class BluetoothHelper {
  /// Auto-connect ke printer terakhir yang tersimpan di SettingsProvider
  /// Returns true jika berhasil connect, false jika gagal
  static Future<bool> autoConnectPrinter(SettingsProvider settingsProvider) async {
    try {
      print('🔵 [BluetoothHelper] Memulai auto-connect...');

      // 1. Minta izin bluetooth dan lokasi
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool hasPermission = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      if (!hasPermission) {
        print('❌ [BluetoothHelper] Izin bluetooth ditolak');
        return false;
      }

      // 2. Ambil printer yang tersimpan di Provider
      var savedPrinter = settingsProvider.selectedPrinter;
      if (savedPrinter == null) {
        print(' [BluetoothHelper] Belum ada printer yang tersimpan di provider');
        return false;
      }

      print('📠 [BluetoothHelper] Printer tersimpan: ${savedPrinter.name} (${savedPrinter.macAdress})');

      // 3. Cek status koneksi sekarang
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      
      // 4. Kalau belum connect, coba connect ke printer tersimpan
      if (!isConnected) {
        print('🔌 [BluetoothHelper] Mencoba connect ke printer...');
        bool connectResult = await PrintBluetoothThermal.connect(
          macPrinterAddress: savedPrinter.macAdress,
        );
        
        if (connectResult) {
          print('✅ [BluetoothHelper] Berhasil auto-connect ke printer');
          return true;
        } else {
          print('❌ [BluetoothHelper] Gagal connect ke printer');
          return false;
        }
      } else {
        // Sudah terhubung
        print('✅ [BluetoothHelper] Printer sudah terhubung');
        return true;
      }
    } catch (e) {
      print(' [BluetoothHelper] Error auto-connect bluetooth: $e');
      return false;
    }
  }

  /// Cek apakah printer sudah terhubung
  static Future<bool> isPrinterConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect printer
  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      print('🔌 [BluetoothHelper] Printer disconnected');
    } catch (e) {
      print('❌ [BluetoothHelper] Error disconnect: $e');
    }
  }
}
