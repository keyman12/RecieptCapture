//
//  Cam5App.swift
//  Cam5
//
//  Created by David Key on 04/05/2025.
//

import SwiftUI
import SwiftyDropbox

@main
struct Cam5App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("SwiftUI: Received URL callback in onOpenURL: \(url)")
                    _ = appDelegate.application(UIApplication.shared, open: url, options: [:])
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("AppDelegate: Application did finish launching")
        
        // Initialize Dropbox only once at app launch
        DropboxClientsManager.setupWithAppKey("nz20x9qbvapry4c")
        print("AppDelegate: Dropbox initialized with app key")
        
        // Handle any URLs that were passed to the app on launch
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            print("AppDelegate: Found URL in launch options: \(url)")
            _ = self.application(application, open: url, options: [:])
        }
        
        // Check if we need to authenticate
        if DropboxClientsManager.authorizedClient == nil {
            print("AppDelegate: No authorized client available, checking for stored credentials")
            // DropboxManager will attempt to restore from keychain
            DropboxManager.shared.checkAuthentication()
        } else {
            print("AppDelegate: Dropbox client already available")
            DropboxManager.shared.checkAuthentication()
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("AppDelegate: Received URL callback: \(url)")
        print("AppDelegate: URL components: \(URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? [])")
        
        // Check if this is a Dropbox URL callback
        guard url.scheme?.hasPrefix("db-") == true else {
            print("AppDelegate: Not a Dropbox URL")
            return false
        }
        
        print("AppDelegate: Processing Dropbox URL callback")
        let oauthCompletion: DropboxOAuthCompletion = { authResult in
            print("AppDelegate: Auth result received: \(String(describing: authResult))")
            
            DispatchQueue.main.async {
                if let authResult = authResult {
                    switch authResult {
                    case .success:
                        print("AppDelegate: Dropbox auth success - setting authenticated state")
                        DropboxManager.shared.isAuthenticated = true
                        DropboxManager.shared.checkAuthentication()
                        NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationSuccess"), object: nil)
                        
                    case .cancel:
                        print("AppDelegate: Authorization flow was manually canceled by user!")
                        DropboxManager.shared.isAuthenticated = false
                        NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                        
                    case .error(_, let description):
                        print("AppDelegate: Dropbox auth error: \(String(describing: description))")
                        DropboxManager.shared.isAuthenticated = false
                        NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                    }
                } else {
                    print("AppDelegate: No auth result received")
                    DropboxManager.shared.isAuthenticated = false
                    NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                }
            }
        }
        
        let canHandle = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
        print("AppDelegate: URL handled: \(canHandle)")
        return canHandle
    }
}

// Helper extension to parse URL parameters
extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        
        var items: [String: String] = [:]
        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value
        }
        return items
    }
}
