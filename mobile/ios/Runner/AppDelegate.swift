import Flutter
import GoogleMaps
import UIKit
import UserNotifications
// Required for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Without a delegate iOS never reports notification taps (nor shows
    // notifications in the foreground) to flutter_local_notifications.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // Key comes from the git-ignored ios/Flutter/Secrets.xcconfig (MAPS_API_KEY_IOS).
    GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? "")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Lets notification actions reach plugins from the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
