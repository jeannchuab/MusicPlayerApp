import SwiftUI
import Testing
@testable import MusicPlayerApp

/// Coverage tests for the reusable custom sheet presentation heuristics.
struct CustomSheetViewTests {

    // MARK: - Tests

    @Test func hiddenOffsetPushesTheSheetBelowTheViewport() {
        #expect(CustomSheetView<EmptyView>.hiddenOffset(for: 200) == 234)
    }

    @Test func shouldDismissUsesTranslationAndPredictedEndThresholds() {
        #expect(CustomSheetView<EmptyView>.shouldDismiss(translation: 73, predictedEndTranslation: 0))
        #expect(CustomSheetView<EmptyView>.shouldDismiss(translation: 0, predictedEndTranslation: 129))
        #expect(CustomSheetView<EmptyView>.shouldDismiss(translation: 30, predictedEndTranslation: 50) == false)
    }
}
