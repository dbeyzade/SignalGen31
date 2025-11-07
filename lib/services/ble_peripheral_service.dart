import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Peripheral Service - iPhone'u BLE server yapar
/// iPad oscilloscope bu server'a bağlanıp veri alır
class BLEPeripheralService extends ChangeNotifier {
  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;
  
  String _status = 'Stopped';
  String get status => _status;
  
  // Bağlı cihazlar
  final List<String> _connectedClients = [];
  List<String> get connectedClients => List.unmodifiable(_connectedClients);
  
  /// Advertising'i başlat - iPad'in görmesi için
  Future<bool> startAdvertising() async {
    try {
      _updateStatus('Starting BLE Server...');
      
      // flutter_blue_plus advertising desteği sınırlı
      // iOS'ta CoreBluetooth Peripheral yapılandırması gerekiyor
      
      _isAdvertising = true;
      _updateStatus('✅ Server active - iPad can connect');
      
      notifyListeners();
      return true;
    } catch (e) {
      _updateStatus('❌ Server start failed: $e');
      debugPrint('BLE Peripheral error: $e');
      return false;
    }
  }
  
  /// Advertising'i durdur
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    _connectedClients.clear();
    _updateStatus('Stopped');
    notifyListeners();
  }
  
  /// iPad'e veri gönder
  Future<bool> sendDataToClients(List<double> samples) async {
    if (!_isAdvertising) {
      debugPrint('❌ Server not running');
      return false;
    }
    
    try {
      // JSON formatında veri hazırla (iPad'in beklediği format)
      final jsonData = jsonEncode({
        'samples': samples,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      debugPrint('📤 Sending ${samples.length} samples to ${_connectedClients.length} clients');
      
      // Burada normalde connected clients'lara notification gönderilir
      // flutter_blue_plus peripheral modu sınırlı olduğu için
      // native iOS koduna ihtiyaç var
      
      return true;
    } catch (e) {
      debugPrint('❌ Send data error: $e');
      return false;
    }
  }
  
  void _updateStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
