//
//  MusicPlayerAppTests.swift
//  MusicPlayerAppTests
//
//  Created by Jeann Luiz Chuab on 19/04/26.
//

import Testing
@testable import MusicPlayerApp

struct MusicPlayerAppTests {

    @MainActor
    @Test func baselineScope() async throws {
        #expect(ChallengeScope.appName == "MusicPlayer")
        #expect(ChallengeScope.supportsDedicatedIPadExperience == false)
    }

}
