# RecieptCapture
Simple receipt capture app, uploads to Dropbox

# Cam5 iOS App

## Overview
Cam5 is an iOS application that seamlessly integrates with Dropbox for file storage and synchronization. The app features automatic authentication and efficient file upload capabilities.

## Features
- Automatic Dropbox authentication
- Seamless file uploads to Dropbox
- Background task handling
- Memory-safe implementation
- Modern Swift implementation

## Technical Details
- **Platform**: iOS
- **Swift Version**: Swift 5+
- **Minimum iOS Version**: iOS 13.0+
- **Dependencies**:
  - Dropbox SDK
  - SwiftUI (for modern UI components)

## Installation
1. Clone the repository
2. Install dependencies
3. Open the `.xcodeproj` file in Xcode
4. Build and run the project

## Configuration
To use the Dropbox integration:
1. Ensure you have a Dropbox developer account
2. Configure your Dropbox API credentials in the app
3. Add your Dropbox API key to the appropriate configuration file

## Key Components
### DropboxManager
The `DropboxManager.swift` file handles all Dropbox-related operations including:
- Authentication flow
- File upload management
- Session handling
- Background task coordination

## Version History
- **Version 3.0** (Current)
  - Improved Dropbox integration
  - Fixed trailing closure syntax issues
  - Enhanced memory management with weak self references
  - Stable authentication and file upload implementation

## Best Practices Implemented
- Proper memory management using `[weak self]`
- Non-trailing closure syntax for clarity
- Explicit closure variables for async operations
- Thread-safe operations using `DispatchQueue`

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
[Your License Here]

## Contact
[Your Contact Information]
