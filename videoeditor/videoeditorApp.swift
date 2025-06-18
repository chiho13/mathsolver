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
    let container: ModelContainer
    
    init() {
        // Lock orientation to portrait
        AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
        
        // Initialize SwiftData container
        do {
            container = try ModelContainer(for: SearchHistoryItem.self)
        } catch {
            fatalError("Failed to create ModelContainer for SearchHistoryItem: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
