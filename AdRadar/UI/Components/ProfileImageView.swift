import SwiftUI

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: Image] = [:]
    
    func image(for url: URL) -> Image? {
        return cache[url]
    }
    
    func setImage(_ image: Image, for url: URL) {
        cache[url] = image
    }
}

struct ProfileImageView: View {
    let url: URL?
    @State private var cachedImage: Image?
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                cachedImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    .shadow(radius: 1)
            } else if let url = url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        .shadow(radius: 1)
                        .onAppear {
                            Task {
                                await ImageCache.shared.setImage(image, for: url)
                                cachedImage = image
                            }
                        }
                } placeholder: {
                    ProgressView()
                        .frame(width: 36, height: 36)
                }
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            if let url = url {
                cachedImage = await ImageCache.shared.image(for: url)
            }
        }
    }
} 