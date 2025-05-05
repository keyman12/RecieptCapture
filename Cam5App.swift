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
        
        // Check if we need to authenticate
        if DropboxClientsManager.authorizedClient == nil {
            print("AppDelegate: Dropbox not authenticated, will need to authenticate")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
            }
        } else {
            print("AppDelegate: Dropbox already authenticated")
            DropboxManager.shared.checkAuthentication()
        }
        
        // Handle any URLs that were passed to the app on launch
        if let url = launchOptions?[.url] as? URL {
            print("AppDelegate: Found URL in launch options: \(url)")
            return application(application, open: url, options: [:])
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("AppDelegate: Received URL callback: \(url)")
        print("AppDelegate: URL components: \(URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? [])")
        print("AppDelegate: URL scheme: \(url.scheme ?? "nil")")
        
        // Check if this is a Dropbox URL callback
        guard url.scheme?.hasPrefix("db-") == true else {
            print("AppDelegate: Not a Dropbox URL")
            return false
        }
        
        print("AppDelegate: Processing Dropbox URL callback")
        let canHandle = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false) { [weak self] authResult in
            print("AppDelegate: Auth result received: \(authResult)")
            
            DispatchQueue.main.async {
                switch authResult {
                case .success:
                    print("AppDelegate: Dropbox auth success - setting authenticated state")
                    // First set the authentication state
                    DropboxManager.shared.isAuthenticated = true
                    // Then verify the token
                    DropboxManager.shared.checkAuthentication()
                    // Finally notify others
                    NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationSuccess"), object: nil)
                    
                case .error(_, let description):
                    print("AppDelegate: Dropbox auth error: \(String(describing: description))")
                    DropboxManager.shared.isAuthenticated = false
                    NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                    
                case .cancel:
                    print("AppDelegate: Dropbox auth cancelled")
                    DropboxManager.shared.isAuthenticated = false
                    NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                    
                case .none:
                    print("AppDelegate: Dropbox auth none")
                    DropboxManager.shared.isAuthenticated = false
                    NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
                }
            }
        }
        
        print("AppDelegate: URL handled: \(canHandle)")
        return canHandle
    }
}

 