import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// BLE Server Service - Native iOS CoreBluetooth kullanır
/// iPad oscilloscope bu server'a bağlanır ve veri alır
class BLEServerService extends ChangeNotifier {
  static const platform = MethodChannel('com.signalgen/ble_peripheral');
  
  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String _status = 'Stopped';
  String get status => _status;
  
  BLEServerService() {
    // Listen for connection changes
    platform.setMethodCallHandler(_handleMethodCall);
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onConnectionChanged') {
      _isConnected = call.arguments as bool;
      _updateStatus(_isConnected ? '✅ iPad Connected' : '⚠️ iPad Disconnected');
      notifyListeners();
    }
  }
  
  /// BLE Server'ı başlat (Native iOS CoreBluetooth)
  Future<bool> startAdvertising() async {
    try {
      _updateStatus('Starting BLE Server...');
      
      final result = await platform.invokeMethod('startBLEServer');
      
      if (result == true) {
        _isAdvertising = true;
        _updateStatus('✅ BLE Server Active\nWaiting for iPad...');
        debugPrint('✅ Native BLE Server started');
        notifyListeners();
        return true;
      }
      
      throw Exception('Failed to start');
    } catch (e) {
      _updateStatus('❌ Server error: $e');
      debugPrint('❌ BLE Server error: $e');
      _isAdvertising = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Advertising'i durdur
  Future<void> stopAdvertising() async {
    try {
      await platform.invokeMethod('stopBLEServer');
      _isAdvertising = false;
      _isConnected = false;
      _updateStatus('Server Stopped');
      debugPrint('🛑 BLE Server stopped');
      notifyListeners();
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }
  
  /// iPad'e veri gönder (Native CoreBluetooth notify)
  Future<bool> sendDataToClients(List<double> samples) async {
    if (!_isAdvertising) {
      debugPrint('❌ Server not running');
      return false;
    }
    
    try {
      // SADECE samples array'ini JSON olarak gönder
      // iPad oscilloscope bunu bekliyor
      final jsonString = jsonEncode(samples);
      
      debugPrint('📤 Sending ${samples.length} samples to iPad (connected: $_isConnected)');
      debugPrint('🔍 First 5 samples: ${samples.take(5).toList()}');
      
      // Native iOS'a gönder
      final success = await platform.invokeMethod('sendData', {
        'data': jsonString,
      });
      
      if (success == true) {
        debugPrint('✅ Data sent successfully');
        return true;
      }
      
      debugPrint('❌ Failed to send data - return value: $success');
      return false;
    } catch (e) {
      debugPrint('❌ Send error: $e');
      return false;
    }
  }
  
  void _updateStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopAdvertising();
    super.dispose();
  }
}
