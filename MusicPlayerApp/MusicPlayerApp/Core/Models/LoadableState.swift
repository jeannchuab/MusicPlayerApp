import Foundation

/// Represents the lifecycle of an asynchronously loaded value.
///
/// Use this enum to drive UI state for screens that fetch remote data, mapping each case
/// to the appropriate loading indicator, content view, empty state, or error view.
enum LoadableState<Value: Equatable>: Equatable {

    /// No load has been attempted yet.
    case idle

    /// A load is currently in progress.
    case loading

    /// The load completed successfully with the associated value.
    case loaded(Value)

    /// The load completed successfully but returned no results.
    case empty

    /// The load failed with the associated ``AppError``.
    case failed(AppError)
}
