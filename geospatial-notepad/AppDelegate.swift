//
//  AppDelegate.swift
//  geospatial-notepad
//
//  Created by Alex Yang on 11/25/21.
//

import UIKit
import ArcGIS

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // hardcoding is bad but writing good code takes time
        AGSArcGISRuntimeEnvironment.apiKey = "AAPKfbb8ec174b1b4978a1ca368744b25c78B4W2_gnZHgkJ_pwP2nixjW_y507eqjITdZr2NLwEGmYeyf6XsuCqc6mLap_2WPGZ"
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

