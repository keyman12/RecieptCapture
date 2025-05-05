import Foundation

extension Notification.Name {
    static let dropboxAuthenticationRequired = Notification.Name("DropboxAuthenticationRequired")
    static let dropboxTokenRefresh = Notification.Name("SwiftyDropboxAPI.tokenRefresh")
    static let dropboxAuthenticationSuccess = Notification.Name("DropboxAuthenticationSuccess")
}

class DropboxManager: ObservableObject {
    @Published private(set) var isAuthenticated = false {
        didSet {
            print("Authentication state changed: \(oldValue) -> \(isAuthenticated)")
        }
    }
    @Published private(set) var isRefreshing = false
    
    static let shared = DropboxManager()
    private let keychainTokenKey = "com.dkexpenses.dropboxToken"
    
    private init() {
        // Try to restore token from keychain
        if retrieveTokenFromKeychain() != nil {
            print("Found token in keychain, attempting to initialize Dropbox client")
            DropboxClientsManager.setupWithAppKey("nz20x9qbvapry4c")
            // Token will be validated in checkAuthentication
        }
        
        // Check authentication status
        Task {
            await checkAuthentication()
        }
        
        // Add notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRefresh),
            name: .dropboxTokenRefresh,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationSuccess),
            name: .dropboxAuthenticationSuccess,
            object: nil
        )
    }
    
    @objc private func handleTokenRefresh(_ notification: Notification) {
        DispatchQueue.main.sync {
            self.isRefreshing = true
            if let error = notification.userInfo?["error"] as? Error {
                print("Token refresh error: \(error)")
                self.handleTokenExpiration()
            } else {
                print("Token refresh successful")
                // Save the refreshed token
                if let client = DropboxClientsManager.authorizedClient,
                   let token = client.accessToken {
                    self.saveTokenToKeychain(token)
                }
                self.isRefreshing = false
                Task {
                    await self.checkAuthentication()
                }
            }
        }
    }

    @objc private func handleAuthenticationSuccess() {
        DispatchQueue.main.sync {
            print("Received authentication success notification")
            self.isAuthenticated = true
            // Save the new token
            if let client = DropboxClientsManager.authorizedClient,
               let token = client.accessToken {
                self.saveTokenToKeychain(token)
            }
            print("Authentication success - state set to true")
            Task {
                await self.checkAuthentication()
            }
        }
    }

    private func handleTokenExpiration() {
        print("Handling token expiration")
        self.isAuthenticated = false
        self.removeTokenFromKeychain()
        NotificationCenter.default.post(name: .dropboxAuthenticationRequired, object: nil)
    }

    func checkAuthentication() async {
        let wasAuthenticated = isAuthenticated
        let hasClient = DropboxClientsManager.authorizedClient != nil
        print("Checking authentication - was authenticated: \(wasAuthenticated), has client: \(hasClient)")
        
        if hasClient {
            // First set the state based on client availability
            isAuthenticated = true
            print("Client available, setting authenticated to true")
            
            // Then verify the token asynchronously
            do {
                let response = try await DropboxClientsManager.authorizedClient?.users.getCurrentAccount().response
                print("Token validation successful")
            } catch {
                print("Token validation failed: \(error)")
                handleTokenExpiration()
            }
        } else {
            print("No client available, setting authenticated to false")
            isAuthenticated = false
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
                        DispatchQueue.main.sync {
                            self?.isAuthenticated = false
                            NotificationCenter.default.post(
                                name: .dropboxAuthenticationRequired,
                                object: nil
                            )
                        }
                    }
                }
            },
            scopeRequest: scopeRequest
        )
    }

    private enum DropboxError: Error {
        case notAuthenticated
        case noAuthorizedClient
        case uploadFailed(Error)
    }

    func uploadFile(data: Data, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            guard isAuthenticated else {
                completion(.failure(DropboxError.notAuthenticated))
                return
            }
            
            guard let client = DropboxClientsManager.authorizedClient else {
                completion(.failure(DropboxError.noAuthorizedClient))
                return
            }
            
            let path = "/\(filename)"
            print("Uploading to path: \(path)")
            
            do {
                let response = try await client.files.upload(path: path, input: data).response
                print("Upload successful: \(response.pathDisplay)")
                completion(.success(response.pathDisplay))
            } catch {
                print("Upload failed: \(error)")
                completion(.failure(DropboxError.uploadFailed(error)))
            }
        }
    }
} 