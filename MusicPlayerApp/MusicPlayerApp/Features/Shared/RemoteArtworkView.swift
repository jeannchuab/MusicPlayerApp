import SwiftUI
import UIKit

/// Loads remote artwork through the shared app artwork cache and renders a placeholder when unavailable.
struct RemoteArtworkView<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    /// The shared app dependencies used to resolve the artwork loader.
    @Environment(\.appDependencies) private var dependencies

    /// The remote artwork URL used as the cache key.
    let url: URL?

    /// The rendered image currently loaded for the view.
    @State private var renderedImage: UIImage?

    /// Builds the success content from the loaded image.
    private let content: (Image) -> Content

    /// Builds the placeholder content shown when no image is available.
    private let placeholder: () -> Placeholder

    // MARK: - Initialization

    /// Creates a remote artwork view with success and placeholder rendering closures.
    ///
    /// - Parameters:
    ///   - url: The remote artwork URL used as the cache key.
    ///   - content: Builds the success content from the loaded image.
    ///   - placeholder: Builds the placeholder content shown when no image is available.
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    // MARK: - Body

    /// Renders the loaded artwork image or the provided placeholder.
    var body: some View {
        Group {
            if let renderedImage {
                content(Image(uiImage: renderedImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadArtwork()
        }
    }

    // MARK: - Helpers

    /// Loads the artwork image for the current URL.
    private func loadArtwork() async {
        guard let url else {
            renderedImage = nil
            return
        }

        renderedImage = await dependencies.artworkLoader.loadImage(from: url)
    }
}
