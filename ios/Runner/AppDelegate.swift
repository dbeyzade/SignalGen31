import Flutter
import UIKit
import CoreBluetooth

// MARK: - BLE Peripheral Manager
class BLEPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    
    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic!
    var connectedCentrals: [CBCentral] = []
    
    // UUID'ler - iPad ile uyumlu
    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")
    
    var onReady: (() -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Start Advertising
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            print("❌ Bluetooth not powered on")
            return
        }
        
        // Create characteristic with notify property
        characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.notify, .read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        // Create service
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        // Add service
        peripheralManager.add(service)
        
        // Start advertising
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "Signal Generator"
        ])
        
        print("✅ BLE Peripheral started advertising")
    }
    
    // MARK: - Stop Advertising
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        connectedCentrals.removeAll()
        print("🛑 BLE Peripheral stopped")
    }
    
    // MARK: - Send Data to Connected Devices
    func sendData(_ data: Data) -> Bool {
        guard !connectedCentrals.isEmpty else {
            print("❌ No connected devices")
            return false
        }
        
        let success = peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: connectedCentrals
        )
        
        if success {
            print("✅ Data sent to \(connectedCentrals.count) device(s)")
        } else {
            print("⚠️ Failed to send, queue full")
        }
        
        return success
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("📱 Peripheral state: \(peripheral.state.rawValue)")
        
        if peripheral.state == .poweredOn {
            onReady?()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("❌ Service add error: \(error)")
        } else {
            print("✅ Service added: \(service.uuid)")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("❌ Advertising error: \(error)")
        } else {
            print("✅ Advertising started")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("✅ Central subscribed: \(central.identifier)")
        connectedCentrals.append(central)
        onConnectionChanged?(true)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("❌ Central unsubscribed: \(central.identifier)")
        connectedCentrals.removeAll { $0.identifier == central.identifier }
        onConnectionChanged?(!connectedCentrals.isEmpty)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("📤 Ready to send more data")
    }
}

// MARK: - App Delegate

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var blePeripheralManager: BLEPeripheralManager?
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Setup method channel for BLE Peripheral
        methodChannel = FlutterMethodChannel(
            name: "com.signalgen/ble_peripheral",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "startBLEServer":
                self.startBLEServer(result: result)
                
            case "stopBLEServer":
                self.stopBLEServer(result: result)
                
            case "sendData":
                if let args = call.arguments as? [String: Any],
                   let dataString = args["data"] as? String,
                   let data = dataString.data(using: .utf8) {
                    self.sendData(data, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid data", details: nil))
                }
                
            case "isConnected":
                result(self.blePeripheralManager?.connectedCentrals.isEmpty == false)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func startBLEServer(result: @escaping FlutterResult) {
        if blePeripheralManager == nil {
            blePeripheralManager = BLEPeripheralManager()
            
            blePeripheralManager?.onReady = { [weak self] in
                self?.blePeripheralManager?.startAdvertising()
                result(true)
            }
            
            blePeripheralManager?.onConnectionChanged = { [weak self] isConnected in
                self?.methodChannel?.invokeMethod("onConnectionChanged", arguments: isConnected)
            }
        } else {
            blePeripheralManager?.startAdvertising()
            result(true)
        }
    }
    
    private func stopBLEServer(result: @escaping FlutterResult) {
        blePeripheralManager?.stopAdvertising()
        result(true)
    }
    
    private func sendData(_ data: Data, result: @escaping FlutterResult) {
        let success = blePeripheralManager?.sendData(data) ?? false
        result(success)
    }
}
