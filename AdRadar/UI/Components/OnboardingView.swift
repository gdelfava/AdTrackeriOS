import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var animateContent = false
    @Binding var showOnboarding: Bool
    
    private let onboardingData = [
        OnboardingPage(
            title: "Track Your AdSense Earnings with Ease",
            subtitle: "See daily, monthly & lifetime reports in one clean dashboard.",
            imageName: "chart.bar.fill",
            backgroundColor: Color.blue
        ),
        OnboardingPage(
            title: "Detailed Analytics & Insights",
            subtitle: "Dive deep into your performance with breakdowns by country, platform, and ad sizes.",
            imageName: "chart.pie.fill",
            backgroundColor: Color.green
        ),
        OnboardingPage(
            title: "Get Started in Seconds",
            subtitle: "Simply sign in with Google to connect your AdSense account and start tracking.",
            imageName: "person.circle.fill",
            backgroundColor: Color.purple
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main content area
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingData[index],
                            animateContent: animateContent
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.6), value: currentPage)
                
                // Bottom section with controls
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if currentPage < onboardingData.count - 1 {
                            Button(action: nextPage) {
                                HStack {
                                    Text("Next")
                                        .font(.body.weight(.semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(onboardingData[currentPage].backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(OnboardingButtonStyle())
                            
                            Button(action: skipOnboarding) {
                                Text("Skip")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: skipOnboarding) {
                                HStack {
                                    Text("Get Started")
                                        .font(.body.weight(.semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(onboardingData[currentPage].backgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(OnboardingButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24))
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 && currentPage < onboardingData.count - 1 {
                        nextPage()
                    } else if value.translation.width > 50 && currentPage > 0 {
                        previousPage()
                    }
                }
        )
    }
    
    private func nextPage() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage += 1
        }
    }
    
    private func previousPage() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage -= 1
        }
    }
    
    private func skipOnboarding() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            showOnboarding = false
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let animateContent: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Illustration area
            VStack(spacing: 32) {
                // Icon illustration
                ZStack {
                    Circle()
                        .fill(page.backgroundColor.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Circle()
                        .fill(page.backgroundColor.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateContent ? 1.0 : 0.6)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Image(systemName: page.imageName)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(page.backgroundColor)
                        .scaleEffect(animateContent ? 1.0 : 0.4)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                
                // Text content
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
                    
                    Text(page.subtitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                }
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundColor: Color
}

struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
} 