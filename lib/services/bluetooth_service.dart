import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signal_type.dart';
import '../models/signal_parameters.dart';
import '../models/favorite_device.dart';

class BluetoothService extends ChangeNotifier {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  
  bool _isScanning = false;
  bool _isConnected = false;
  List<fbp.ScanResult> _scanResults = [];
  List<FavoriteDevice> _favoriteDevices = [];
  
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<fbp.ScanResult> get scanResults => _scanResults;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  List<FavoriteDevice> get favoriteDevices => _favoriteDevices;

  // UUID'ler - Bu değerleri tablet uygulamanızın UUID'leriyle eşleştirin
  static const String serviceUUID = "0000FFE0-0000-1000-8000-00805F9B34FB";
  static const String characteristicUUID = "0000FFE1-0000-1000-8000-00805F9B34FB";

  BluetoothService() {
    _loadFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_devices');
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      _favoriteDevices = decoded.map((e) => FavoriteDevice.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_favoriteDevices.map((e) => e.toJson()).toList());
    await prefs.setString('favorite_devices', encoded);
  }

  // Add device to favorites
  Future<bool> addToFavorites(String deviceId, String deviceName) async {
    if (_favoriteDevices.any((d) => d.id == deviceId)) {
      return false; // Already in favorites
    }
    
    _favoriteDevices.add(FavoriteDevice(
      id: deviceId,
      name: deviceName,
      addedAt: DateTime.now(),
    ));
    
    await _saveFavorites();
    notifyListeners();
    return true;
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String deviceId) async {
    _favoriteDevices.removeWhere((d) => d.id == deviceId);
    await _saveFavorites();
    notifyListeners();
  }

  // Update custom name
  Future<void> updateDeviceName(String deviceId, String customName) async {
    final index = _favoriteDevices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _favoriteDevices[index] = FavoriteDevice(
        id: _favoriteDevices[index].id,
        name: _favoriteDevices[index].name,
        customName: customName.isEmpty ? null : customName,
        addedAt: _favoriteDevices[index].addedAt,
      );
      await _saveFavorites();
      notifyListeners();
    }
  }

  // Check if device is favorite
  bool isFavorite(String deviceId) {
    return _favoriteDevices.any((d) => d.id == deviceId);
  }

  // Get custom name for device
  String? getCustomName(String deviceId) {
    final fav = _favoriteDevices.where((d) => d.id == deviceId).firstOrNull;
    return fav?.customName;
  }

  Future<void> startScan() async {
    _scanResults.clear();
    _isScanning = true;
    notifyListeners();

    try {
      // Check if Bluetooth is supported and enabled
      if (await fbp.FlutterBluePlus.isSupported == false) {
        debugPrint("Bluetooth not supported");
        return;
      }

      // Start scanning
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });

      // Listen for scan completion
      fbp.FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _isScanning) {
          // Scan finished but keep results visible
          _isScanning = false;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint("Scan error: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      debugPrint("🔵 Starting connection to ${device.platformName}...");
      
      // iOS doesn't support bondState checking, so we skip pairing check
      // iOS handles pairing automatically when needed
      debugPrint("🔌 Connecting...");
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) {
        _isConnected = state == fbp.BluetoothConnectionState.connected;
        if (!_isConnected) {
          _connectedDevice = null;
          _txCharacteristic = null;
        }
        notifyListeners();
      });

      // Discover services
      debugPrint("🔍 Discovering services...");
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      debugPrint("Found ${services.length} services");
      
      // Find the characteristic for data transmission
      for (var service in services) {
        debugPrint("Service: ${service.uuid}");
        for (var characteristic in service.characteristics) {
          debugPrint("  Characteristic: ${characteristic.uuid}, Write: ${characteristic.properties.write}, WriteNoResp: ${characteristic.properties.writeWithoutResponse}");
          
          if (characteristic.properties.write || 
              characteristic.properties.writeWithoutResponse) {
            _txCharacteristic = characteristic;
            debugPrint("✓ Using TX Characteristic: ${characteristic.uuid}");
            break;
          }
        }
        if (_txCharacteristic != null) break;
      }

      if (_txCharacteristic == null) {
        debugPrint("⚠️ No writable characteristic found!");
        _isConnected = false;
        await device.disconnect();
        notifyListeners();
        return false;
      }

      _isConnected = true;
      notifyListeners();
      debugPrint("✅ Successfully connected to ${device.platformName}");
      return true;
    } catch (e) {
      debugPrint("❌ Connection error: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      await _connectionSubscription?.cancel();
      _connectedDevice = null;
      _txCharacteristic = null;
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }
  }

  Future<bool> sendSignalData(
    SignalType signalType,
    SignalParameters parameters,
    List<double> samples,
  ) async {
    if (!_isConnected) {
      debugPrint("❌ Cannot send: Not connected to device");
      return false;
    }
    
    if (_txCharacteristic == null) {
      debugPrint("❌ Cannot send: No TX characteristic found");
      return false;
    }

    try {
      debugPrint("📤 Preparing to send signal data...");
      
      // Create JSON data packet
      final data = {
        'version': '1.0',
        'signal': {
          'type': signalType.toString().split('.').last,
          'frequency': parameters.frequency,
          'amplitude': parameters.amplitude,
          'phase': parameters.phase,
          'offset': parameters.offset,
          'samples': samples,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      };

      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      debugPrint("📦 Data size: ${bytes.length} bytes");

      // Split data into chunks if needed (BLE has MTU limitations)
      const int chunkSize = 512;
      int chunksCount = (bytes.length / chunkSize).ceil();
      
      debugPrint("📨 Sending $chunksCount chunks...");
      
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        
        await _txCharacteristic!.write(chunk, withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 20));
        
        debugPrint("  Chunk ${(i / chunkSize).floor() + 1}/$chunksCount sent");
      }

      debugPrint("✅ Signal data sent successfully");
      return true;
    } catch (e) {
      debugPrint("❌ Send data error: $e");
      return false;
    }
  }

  Future<bool> sendSignalParameters(
    SignalType signalType,
    SignalParameters parameters,
  ) async {
    if (!_isConnected || _txCharacteristic == null) {
      return false;
    }

    try {
      // Send only parameters without samples for efficiency
      final data = {
        'version': '1.0',
        'signal': {
          'type': signalType.toString().split('.').last,
          'frequency': parameters.frequency,
          'amplitude': parameters.amplitude,
          'phase': parameters.phase,
          'offset': parameters.offset,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      };

      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      await _txCharacteristic!.write(bytes, withoutResponse: true);
      return true;
    } catch (e) {
      debugPrint("Send parameters error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}
