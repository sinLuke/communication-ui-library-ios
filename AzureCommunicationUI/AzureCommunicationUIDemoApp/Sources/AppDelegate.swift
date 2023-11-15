//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit
import AppCenter
import AppCenterCrashes
import CallKit
import AzureCommunicationUICalling
import PushKit
import OSLog

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {

    static var orientationLock: UIInterfaceOrientationMask = .all

    let envConfigSubject = EnvConfigSubject()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        AppCenter.start(withAppSecret: envConfigSubject.appCenterSecret, services: [Crashes.self])
        self.setupNotifications(application: application)
        return true
    }

    public func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else {
            return
        }

        let tokenString = self.tokenString(from: pushCredentials.token)
        print("VoIP Token: \(tokenString)")

        if let entryViewController = findEntryViewController() {
            entryViewController.registerDeviceToken(deviceCode: pushCredentials.token)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        print("pushRegistry payload: \(payload.dictionaryPayload)")

        if isAppInForeground() {
            os_log("calling demo app: app is in foreground")
            if let entryViewController = findEntryViewController() {
                os_log("calling demo app: onPushNotificationReceived")
                entryViewController.onPushNotificationReceived(dictionaryPayload: payload.dictionaryPayload)
            }
        } else {
            os_log("calling demo app: app is not in foreground")
            let pushInfo = CallCompositePushNotificationInfo(pushNotificationInfo: payload.dictionaryPayload)
            let cxHandle = CXHandle(type: .generic, value: "\(pushInfo.pushNotificationInfo.callId)")
            let cxProvider = CallCompositeCallKitOption.getDefaultCXProviderConfiguration()
            let remoteInfo = CallCompositeCallKitRemoteInfo(displayName: pushInfo.pushNotificationInfo.fromDisplayName,
                                                            cxHandle: cxHandle)
            let callKitOptions = CallCompositeCallKitOption(cxProvideConfig: cxProvider,
                                                            isCallHoldSupported: true,
                                                            remoteInfo: remoteInfo)
            CallComposite.reportIncomingCall(callKitOptions: callKitOptions,
                                             callNotification: pushInfo) { result in
                if case .success() = result {
                    DispatchQueue.global().async {
                        if let entryViewController = self.findEntryViewController() {
                            os_log("calling demo app: onPushNotificationReceivedBackgroundMode")
                            entryViewController.onPushNotificationReceivedBackgroundMode(
                                dictionaryPayload: payload.dictionaryPayload)
                        }
                    }
                } else {
                    os_log("calling demo app: failed on reportIncomingCall")
                }
            }
        }
    }

    private func isAppInForeground() -> Bool {
        let appState = UIApplication.shared.applicationState

        switch appState {
        case .active:
            return true
        default:
            return false
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.voipRegistration()
    }

    private func tokenString(from data: Data) -> String {
        return data.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // Register for VoIP notifications
    private func voipRegistration() {
        let mainQueue = DispatchQueue.main

        // Create a push registry object
        let voipRegistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    private func findEntryViewController() -> EntryViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootViewController = window.rootViewController as? UINavigationController,
              let entryViewController = rootViewController.viewControllers.first as? EntryViewController else {
            return nil
        }
        return entryViewController
    }

    private func setupNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, _) in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
}
