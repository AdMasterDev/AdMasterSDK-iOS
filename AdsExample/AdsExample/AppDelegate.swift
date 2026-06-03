//
//  AppDelegate.swift
//  AdsExample
//
//  Created by Mingming on 2026/6/3.
//

import UIKit
import AdMasterSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // mock mode setting
        UserDefaults.standard.register(defaults: [SampleConfig.mockModeKey: false])
        ADMSetting.sharedInstance().isMock = UserDefaults.standard.bool(forKey: SampleConfig.mockModeKey)
        // SDK init
        ADMManager.start(withAppsid: SampleConfig.appSID) { success, error in
            if success {
                NSLog("AdMasterSDK initialized successfully")
            } else {
                NSLog("AdMasterSDK initialization failed: %@", String(describing: error))
            }
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}
