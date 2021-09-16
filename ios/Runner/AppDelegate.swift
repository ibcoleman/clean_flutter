import UIKit
import Flutter
import ExternalAccessory

enum ChannelName {
    static let rfidconnect = "samples.flutter.io/rfidconnect"
    static let rfiddisconnect = "samples.flutter.io/rfiddisconnect"
}

enum MyFlutterErrorCode {
  static let unavailable = "UNAVAILABLE"
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
    private var rfidConnectChannel: FlutterEventChannel?
  //private var accessoryManager: EAAccessoryManager?
    
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    EAAccessoryManager.shared().registerForLocalNotifications()
    
    
    let rfidConnectChannel = FlutterEventChannel(name: ChannelName.rfidconnect, binaryMessenger: controller.binaryMessenger)
    rfidConnectChannel.setStreamHandler(self)
    let rfidDisconnectChannel = FlutterEventChannel(name: ChannelName.rfiddisconnect, binaryMessenger: controller.binaryMessenger)
    rfidDisconnectChannel.setStreamHandler(self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }



  public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    //self.eventSink = eventSink
    let args = arguments as? [String]
    switch args?.first {
    case "connect":
        NotificationCenter.default.addObserver(forName: NSNotification.Name.EAAccessoryDidConnect, object: nil, queue: OperationQueue.current) { notification in
            self.sendAccessoryConnectEvent(notification: notification, eventSink: eventSink)
        }

    case "disconnect":
        NotificationCenter.default.addObserver(forName: NSNotification.Name.EAAccessoryDidDisconnect, object: nil, queue: OperationQueue.current) { notification in
            self.sendAccessoryDisconnectEvent(notification: notification, eventSink: eventSink)
        }
    default:
        print("Bad listen argument was \(args?.first ?? "empty")")
    }

    return nil

  }

    private func sendAccessoryConnectEvent(notification: Notification, eventSink: FlutterEventSink) {
        eventSink(notification.description)
    }
            
    private func sendAccessoryDisconnectEvent(notification: Notification, eventSink: FlutterEventSink) {
        eventSink(notification.description)
    }
    

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
