import SwiftUI

struct ProfileImageView: View {
    let url: URL?

    var body: some View {
        if let url = url {
            AsyncImage(url: url) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
            .shadow(radius: 1)
        } else {
            Image(systemName: "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .foregroundColor(.secondary)
        }
    }
} 