//
//  ContentView.swift
//  Cam5
//
//  Created by David Key on 04/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true
    @StateObject private var imageCapture = ImageCapture()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            if !showingSplash {
                NavigationView {
                    VStack {
                        // Title Section
                        VStack(spacing: 2) {
                            Text("Receipt Capture")
                                .font(.largeTitle)
                                .foregroundColor(.black)
                            Text("DJIL Automation")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        // Camera Button
                        Button(action: {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                imageCapture.showingImagePicker = true
                            } else {
                                alertMessage = "Camera is not available on this device. Using photo library instead."
                                showingAlert = true
                                // Still show the picker, it will fallback to photo library
                                imageCapture.showingImagePicker = true
                            }
                        }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                Text("Take Photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        }
                        
                        Spacer()
                        
                        // Logs Button
                        NavigationLink(destination: LogsView(logs: imageCapture.logs)) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("View Logs")
                            }
                            .foregroundColor(.blue)
                            .padding()
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            EmptyView()
                        }
                    }
                    .sheet(isPresented: $imageCapture.showingImagePicker) {
                        CameraController(sourceType: .camera) { image in
                            imageCapture.saveImage(image)
                        }
                    }
                    .alert("Note", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                }
                .transition(.opacity)
                .onAppear {
                    imageCapture.loadLogs()
                }
            }
            
            if showingSplash {
                SplashScreenView(isActive: $showingSplash)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: showingSplash)
    }
}

#Preview {
    ContentView()
}
