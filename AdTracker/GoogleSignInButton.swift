// Reusable Google Sign-In button component
//
//  GoogleSignInButton.swift
//  Adsense Tracker
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct GoogleSignInButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> GIDSignInButton {
        return GIDSignInButton()
    }

    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
}

#if DEBUG
struct GoogleSignInButtonView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInButtonView()
            .frame(width: 200, height: 50)
    }
}
#endif
