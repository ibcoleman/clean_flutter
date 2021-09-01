import UIKit
import Flutter
import TSLAsciiCommands

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
   
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let platformChannel = FlutterMethodChannel(name: "samples.flutter.dev/platformChannel",
                                              binaryMessenger: controller.binaryMessenger)
    
    var _transponders: [TSLTransponderData] = []
    
    // Channel to return battery percentages.
    platformChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            switch call.method {
    
            case "getBatteryLevel":
                self?.receiveBatteryLevel(result: result)

            case "getRfidScan":
                self?.doRfidScan(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Battery info unavailable",
                                details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }

    private func doRfidScan(result: FlutterResult) {
        
        
        var commander: TSLAsciiCommander = TSLAsciiCommander()
        var logger: TSLLoggerResponder = TSLLoggerResponder()
        commander.add(logger)
        commander.addSynchronousResponder()
        
        let accessoryManager: EAAccessoryManager = EAAccessoryManager.shared()
        
        let accessoryList: [EAAccessory] = accessoryManager.connectedAccessories
                
        // Connect via commander
        let accessory: EAAccessory? = accessoryList.first;

        if (!commander.isConnected) {
            commander.connect(accessoryList.first)
        }

        if (commander.isConnected) {
            
            // Set up and execute synchronous Inventory command...
            let invResponder: TSLInventoryCommand = TSLInventoryCommand.synchronousCommand()
            invResponder.captureNonLibraryResponses = true
            invResponder.includeTransponderRSSI = TSL_TriState_YES
            invResponder.includeDateTime = TSL_TriState_YES
            invResponder.includeEPC = TSL_TriState_YES
            
            commander.add(invResponder)

            var transponders: [TSLTransponderData] = []

            invResponder.transponderDataReceivedBlock = { (data: TSLTransponderData, ok: Bool) in
                transponders.append(data)
            }

            commander.execute(invResponder)

            let ok = invResponder.isSuccessful
            
            let results: MyResult = transponderDataToJsonString(transponder: transponders)

            switch results {
            case let .success(success):
                result(success)
                
            case let .failure(error):
                result(FlutterError(code: "ERROR",
                                    message: error.localizedDescription,
                                    details: nil))
            }
            
        } else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Could not connect to accessory \(accessory.debugDescription)",
                                details: nil))
        }
        commander.disconnect()
    }
    
    //
    // Getting the error:  {"epc":"E200002027130088230033F4","rssi":-36,"timestamp":652220044} from timestamp "2021-09-01T16:18:22"

    private func transponderDataToJsonString(transponder: [TSLTransponderData]) -> MyResult {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let responseClass = TransponderResponse(
            transponders: transponder.map {(data: TSLTransponderData) -> TransponderResponseItem in
                        TransponderResponseItem(epc: data.epc!, rssi: data.rssi, timestamp: data.timestamp)
            })
        
        do {
            let responseData: String? = try String(data: encoder.encode(responseClass), encoding: .utf8)
        
            if (responseData?.isEmpty ?? true) {
                return MyResult.failure(MyError.cause("Response Data Was Empty"))
            }

            return MyResult.success(responseData!)

        } catch {
            
            return MyResult.failure(MyError.cause(error.localizedDescription))
        }
    }

}

//
struct TransponderResponseItem: Encodable {
    var epc: String
    var rssi: Int?
    var timestamp: Date?

    init(epc: String, rssi: NSNumber?, timestamp: Date?) {
        self.epc = epc
        self.rssi = rssi?.intValue
        self.timestamp = timestamp
    }
}

struct TransponderResponse: Encodable {
    var transponders: [TransponderResponseItem]
}

typealias MyResult = Result<String, MyError>
enum MyError: Error {
    case cause(String)
}
public enum Result<Success, Failure> where Failure : Error {
    case success(Success)
    case failure(Failure)
}
