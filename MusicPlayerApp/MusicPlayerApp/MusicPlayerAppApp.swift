//
//  MusicPlayerAppApp.swift
//  MusicPlayerApp
//
//  Created by Jeann Luiz Chuab on 19/04/26.
//

import SwiftUI
import SwiftData

@main
struct MusicPlayerAppApp: App {
    private let dependencies = AppDependencies.live

    init() {
        FontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, dependencies)
                .modelContainer(dependencies.modelContainer)
                .font(.app(15))
        }
    }
}
