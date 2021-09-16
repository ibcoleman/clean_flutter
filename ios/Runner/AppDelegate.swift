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

    ///
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    EAAccessoryManager.shared().registerForLocalNotifications()
    
    
    ///
    let rfidConnectChannel = FlutterEventChannel(name: ChannelName.rfidconnect, binaryMessenger: controller.binaryMessenger)
    rfidConnectChannel.setStreamHandler(self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  
  }



  public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {

    NotificationCenter.default.addObserver(forName: NSNotification.Name.EAAccessoryDidConnect, object: nil, queue: OperationQueue.current) { notification in
        self.sendAccessoryConnectEvent(notification: notification, eventSink: eventSink)
    }
    NotificationCenter.default.addObserver(forName: NSNotification.Name.EAAccessoryDidDisconnect, object: nil, queue: OperationQueue.current) { notification in
        self.sendAccessoryDisconnectEvent(notification: notification, eventSink: eventSink)
    }
    return nil

  }

    private func sendAccessoryConnectEvent(notification: Notification, eventSink: FlutterEventSink) {
        // Send {"state": "connect", "id": <an_int_id>} to client
        guard let accessory = notification.userInfo?.first?.value as? EAAccessory else {
            return
        }

        if (accessory.protocolStrings.contains("com.uk.tsl.rfid")) {
            eventSink("'connected': true, 'id': \(accessory.connectionID)")
        }
    }
        
    
    private func sendAccessoryDisconnectEvent(notification: Notification, eventSink: FlutterEventSink) {
        guard let accessory = notification.userInfo?.first?.value as? EAAccessory else {
            return
        }

        if (accessory.protocolStrings.contains("com.uk.tsl.rfid")) {
            eventSink("'connected': false, 'id': \(accessory.connectionID)")
        }
    }
    

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    eventSink = nil
    return nil
  }
}
