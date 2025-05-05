import SwiftUI
import SwiftyDropbox

class DropboxManager: ObservableObject {
    @Published var isAuthenticated = false {
        didSet {
            print("Authentication state changed: \(oldValue) -> \(isAuthenticated)")
        }
    }
    @Published var isRefreshing = false
    static let shared = DropboxManager()
    
    private init() {
        // Check authentication status
        checkAuthentication()
        
        // Add notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRefresh),
            name: NSNotification.Name("SwiftyDropboxAPI.tokenRefresh"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationSuccess),
            name: NSNotification.Name("DropboxAuthenticationSuccess"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleTokenRefresh(_ notification: Notification) {
        let work = { [weak self] in
            guard let self = self else { return }
            self.isRefreshing = true
            if let error = notification.userInfo?["error"] as? Error {
                print("Token refresh error: \(error)")
                self.handleTokenExpiration()
            } else {
                print("Token refresh successful")
                self.isRefreshing = false
                self.checkAuthentication()
            }
        }
        DispatchQueue.main.async(execute: work)
    }
    
    @objc private func handleAuthenticationSuccess() {
        print("Received authentication success notification")
        let work = { [weak self] in
            guard let self = self else { return }
            self.isAuthenticated = true
            print("Authentication success - state set to true")
        }
        DispatchQueue.main.async(execute: work)
    }
    
    func checkAuthentication() {
        let wasAuthenticated = isAuthenticated
        let hasClient = DropboxClientsManager.authorizedClient != nil
        print("Checking authentication - was authenticated: \(wasAuthenticated), has client: \(hasClient)")
        
        if hasClient {
            // First set the state based on client availability
            isAuthenticated = true
            print("Client available, setting authenticated to true")
            
            // Then verify the token asynchronously
            DropboxClientsManager.authorizedClient?.users.getCurrentAccount().response { [weak self] (response: Users.FullAccount?, error: CallError<Void>?) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Token check error: \(error)")
                        self?.handleTokenExpiration()
                    } else {
                        print("Token validated successfully")
                        self?.isAuthenticated = true
                        self?.isRefreshing = false
                    }
                }
            }
        } else {
            print("No authorized client available")
            handleTokenExpiration()
        }
    }
    
    private func handleTokenExpiration() {
        print("Handling token expiration")
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.isRefreshing = false
            // Notify user they need to re-authenticate
            NotificationCenter.default.post(
                name: NSNotification.Name("DropboxAuthenticationRequired"),
                object: nil
            )
        }
    }
    
    func authenticate(from viewController: UIViewController) {
        print("DropboxManager: Starting authentication process")
        let scopeRequest = ScopeRequest(
            scopeType: .user,
            scopes: ["files.content.write", "account_info.read"],
            includeGrantedScopes: false
        )
        print("DropboxManager: Created scope request with write and account info permissions")
        
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: viewController,
            loadingStatusDelegate: nil,
            openURL: { [weak self] url in
                print("DropboxManager: Opening Dropbox auth URL: \(url)")
                UIApplication.shared.open(url, options: [:]) { success in
                    print("DropboxManager: URL open result: \(success)")
                    if !success {
                        DispatchQueue.main.async {
                            self?.isAuthenticated = false
                            NotificationCenter.default.post(
                                name: NSNotification.Name("DropboxAuthenticationRequired"),
                                object: nil
                            )
                        }
                    }
                }
            },
            scopeRequest: scopeRequest
        )
    }
    
    func uploadFile(data: Data, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("Upload requested - current auth state: \(isAuthenticated)")
        
        // First check if we're authenticated
        guard isAuthenticated else {
            print("Upload attempted while not authenticated - requesting authentication")
            NotificationCenter.default.post(name: NSNotification.Name("DropboxAuthenticationRequired"), object: nil)
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please connect to Dropbox first"])))
            return
        }
        
        guard let client = DropboxClientsManager.authorizedClient else {
            print("No authorized client available - requesting authentication")
            handleTokenExpiration()
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please connect to Dropbox first"])))
            return
        }
        
        print("Starting upload process - authenticated: \(isAuthenticated)")
        
        // Check token by making a simple API call
        client.users.getCurrentAccount().response { [weak self] (response: Users.FullAccount?, error: CallError<Void>?) in
            if let error = error {
                print("Token validation error during upload: \(error)")
                DispatchQueue.main.async {
                    self?.handleTokenExpiration()
                    completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Please reconnect to Dropbox"])))
                }
                return
            }
            
            print("Token validated successfully, proceeding with upload")
            let path = "/dkexpenses/inbox/\(filename)"
            
            client.files.upload(path: path, input: data)
                .response { (response: Files.FileMetadata?, error: CallError<Files.UploadError>?) in
                    if let error = error {
                        print("Upload error: \(error)")
                        completion(.failure(error))
                    } else if let metadata = response {
                        print("Upload successful: \(metadata.pathDisplay ?? path)")
                        completion(.success(metadata.pathDisplay ?? path))
                    }
                }
                .progress { progressData in
                    print("Upload progress: \(progressData.fractionCompleted)")
                }
        }
    }
} 
