import SwiftUI
import UIKit

/// A SwiftUI wrapper around `UIActivityViewController` for presenting the native iOS share sheet.
struct SystemShareSheet: UIViewControllerRepresentable {
    /// The values shared through the system activity sheet.
    let items: [Any]

    /// Creates the UIKit share sheet controller.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    /// Keeps the wrapper conforming to `UIViewControllerRepresentable`; no incremental updates are required.
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
