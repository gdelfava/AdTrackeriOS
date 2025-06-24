import SwiftUI

struct WatchLoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Custom loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .animation(
                        Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            }
            
            Text("Updating...")
                .font(.custom("Sora-Regular", size: 10))
                .foregroundColor(.secondary)
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

struct WatchErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.custom("Sora-SemiBold", size: 20))
                .foregroundColor(.orange)
            
            Text("Connection Error")
                .font(.custom("Sora-Medium", size: 14))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.custom("Sora-Regular", size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.custom("Sora-Regular", size: 10))
                    Text("Retry")
                        .font(.custom("Sora-Regular", size: 10))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

struct WatchNoDataView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.custom("Sora-SemiBold", size: 20))
                .foregroundColor(.secondary)
            
            Text("No Data")
                .font(.custom("Sora-Medium", size: 14))
                .foregroundColor(.primary)
            
            Text("Open the iPhone app to sync your AdSense data")
                .font(.custom("Sora-Regular", size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRefresh) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.custom("Sora-Regular", size: 10))
                    Text("Refresh")
                        .font(.custom("Sora-Regular", size: 10))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

#Preview("Loading") {
    WatchLoadingView()
}

#Preview("Error") {
    WatchErrorView(message: "Failed to connect to iPhone") {
        print("Retry tapped")
    }
}

#Preview("No Data") {
    WatchNoDataView {
        print("Refresh tapped")
    }
} 