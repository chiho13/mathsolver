//
//  videoeditorApp.swift
//  videoeditor
//
//  Created by Anthony Ho on 17/06/2025.
//

import SwiftUI
import SwiftData

@main
struct videoeditorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SearchHistoryItem.self,
            Usage.self,
            PDFProject.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema,
                                                    isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var isFirstLaunch: Bool = {
        // Check UserDefaults to see if the app has been launched before
        !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }()

    @StateObject private var iapManager = IAPManager()
    
    @State private var showPremView: Bool = false

    init() {
        // Lock orientation to portrait
        AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
    }
    
    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch, showPremView: $showPremView)
                    .environmentObject(iapManager)
//                    .environment(\.locale, Locale(identifier: "ja"))

            } else {
                if showPremView {
                    OnboardingPremiumView(showPremView: $showPremView)
                        .environmentObject(iapManager)
//                        .environment(\.locale, Locale(identifier: "ja"))
                } else {
                    ContentView()
                        .environmentObject(iapManager)
//                        .environment(\.locale, Locale(identifier: "zh-Hant"))

                }
                  
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
