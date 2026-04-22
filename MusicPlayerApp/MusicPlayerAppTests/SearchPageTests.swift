import Testing
@testable import MusicPlayerApp

/// Coverage tests for `SearchPage` pagination helpers.
@MainActor
struct SearchPageTests {

    // MARK: - Tests

    @Test func nextOffsetAddsTheCurrentSongCountToTheOffset() {
        let page = SearchPage(
            query: "demo",
            offset: 25,
            limit: 25,
            resultCount: 50,
            songs: [.stub(id: 1), .stub(id: 2), .stub(id: 3)]
        )

        #expect(page.nextOffset == 28)
    }

    @Test func canRequestNextPageIsFalseForEmptyAndPartialPages() {
        let emptyPage = SearchPage(
            query: "demo",
            offset: 0,
            limit: 25,
            resultCount: 0,
            songs: []
        )
        let partialPage = SearchPage(
            query: "demo",
            offset: 25,
            limit: 25,
            resultCount: 30,
            songs: [.stub(id: 1), .stub(id: 2)]
        )

        #expect(emptyPage.canRequestNextPage == false)
        #expect(partialPage.canRequestNextPage == false)
    }

    @Test func canRequestNextPageIsTrueWhenThePageIsFull() {
        let page = SearchPage(
            query: "demo",
            offset: 0,
            limit: 3,
            resultCount: 6,
            songs: [.stub(id: 1), .stub(id: 2), .stub(id: 3)]
        )

        #expect(page.canRequestNextPage)
    }
}
