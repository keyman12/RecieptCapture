//
//  ContentView.swift
//  Cam5
//
//  Created by David Key on 04/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true
    
    var body: some View {
        ZStack {
            if !showingSplash {
                NavigationView {
                    VStack {
                        Spacer()
                        
                        // Camera Button
                        Button(action: {
                            // Camera action will be implemented later
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
                        NavigationLink(destination: LogsView()) {
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
                            Text("Receipt Capture")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .transition(.opacity)
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
