import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("DJILLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .onAppear {
            // Ensure we're on the main thread
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false  // We set to false because showingSplash should be false to show main content
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
} 