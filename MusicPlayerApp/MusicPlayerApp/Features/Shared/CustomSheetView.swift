import SwiftUI

/// A reusable bottom sheet container with backdrop, drag-to-dismiss, and presentation animation.
struct CustomSheetView<Content: View>: View {

    // MARK: - Properties

    /// Binding that controls whether the sheet is visible.
    @Binding private var isPresented: Bool

    /// The current downward drag translation applied during interactive dismissal.
    @State private var dragOffset: CGFloat = 0

    /// Keeps content mounted long enough for the dismiss animation to complete cleanly.
    @State private var shouldRenderContent = false

    /// The target content height excluding any bottom safe-area inset.
    private let contentHeight: CGFloat

    /// The top corner radius applied to the sheet container.
    private let cornerRadius: CGFloat

    /// The opacity used for the dimming backdrop.
    private let backdropOpacity: Double

    /// The sheet background fill color.
    private let backgroundColor: Color

    /// The content rendered inside the sheet container.
    private let content: Content

    // MARK: - Initialization

    /// Creates a custom bottom sheet container around the provided content.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls whether the sheet is visible.
    ///   - contentHeight: The height of the sheet content before bottom safe-area padding is added.
    ///   - cornerRadius: The top corner radius applied to the sheet container.
    ///   - backdropOpacity: The opacity used for the dimming backdrop behind the sheet.
    ///   - backgroundColor: The background color rendered behind the sheet content.
    ///   - content: A view builder that creates the sheet content.
    init(
        isPresented: Binding<Bool>,
        contentHeight: CGFloat,
        cornerRadius: CGFloat = 16,
        backdropOpacity: Double = 0.18,
        backgroundColor: Color = Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.96),
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.contentHeight = contentHeight
        self.cornerRadius = cornerRadius
        self.backdropOpacity = backdropOpacity
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    // MARK: - Body

    /// The sheet container, backdrop, and interactive dismissal behavior.
    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
            let sheetHeight = contentHeight + bottomInset
            let hiddenOffset = sheetHeight + 34
            let visibleOffset = isPresented ? dragOffset : hiddenOffset

            ZStack(alignment: .bottom) {
                Color.black.opacity(backdropOpacity)
                    .opacity(isPresented ? 1 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .allowsHitTesting(isPresented)

                if shouldRenderContent {
                    content
                        .frame(maxWidth: .infinity)
                        .frame(height: sheetHeight)
                        .padding(.bottom, bottomInset)
                        .background(backgroundColor)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                                topTrailingRadius: cornerRadius,
                                style: .continuous
                            )
                        )
                        .offset(y: visibleOffset)
                        .simultaneousGesture(dismissGesture)
                        .allowsHitTesting(isPresented)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .allowsHitTesting(isPresented)
        .animation(sheetAnimation, value: isPresented)
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: dragOffset)
        .task {
            shouldRenderContent = isPresented
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                shouldRenderContent = true
            } else {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    guard !isPresented else { return }
                    shouldRenderContent = false
                }
            }
        }
    }

    // MARK: - Helpers

    /// Tracks the interactive drag state and dismisses the sheet when the gesture crosses the threshold.
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragOffset = max(value.translation.height, 0)
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 72 || value.predictedEndTranslation.height > 128

                if shouldDismiss {
                    dismiss()
                } else {
                    dragOffset = 0
                }
            }
    }

    /// Dismisses the sheet and resets any interactive drag state.
    private func dismiss() {
        withAnimation(sheetAnimation) {
            isPresented = false
            dragOffset = 0
        }
    }

    /// The spring animation shared by presentation and dismissal transitions.
    private var sheetAnimation: Animation {
        .spring(response: 0.36, dampingFraction: 0.92, blendDuration: 0.08)
    }
}
