//
//  MusicPlayerAppApp.swift
//  MusicPlayerApp
//
//  Created by Jeann Luiz Chuab on 19/04/26.
//

import SwiftUI
import SwiftData

/// The app entry point that wires shared dependencies into the root SwiftUI scene.
@main
struct MusicPlayerAppApp: App {

    // MARK: - Properties

    /// The shared app dependency container used throughout the app lifecycle.
    private let dependencies = AppDependencies.live

    // MARK: - Initialization

    /// Creates the app and registers bundled fonts before the first scene appears.
    init() {
        FontRegistrar.registerFonts()
    }

    // MARK: - Scenes

    /// The main app scene configured with shared environment values and typography.
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, dependencies)
                .modelContainer(dependencies.modelContainer)
                .font(.app(15))
        }
    }
}
