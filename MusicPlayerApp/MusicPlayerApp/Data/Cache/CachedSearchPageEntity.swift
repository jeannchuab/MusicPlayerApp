import Foundation
import SwiftData

@Model
final class CachedSearchPageEntity {
    @Attribute(.unique) var pageKey: String
    var query: String
    var offset: Int
    var limit: Int
    var resultCount: Int
    var songIDsString: String
    var cachedAt: Date

    init(page: SearchPage, pageKey: String, cachedAt: Date = .now) {
        self.pageKey = pageKey
        query = page.query
        offset = page.offset
        limit = page.limit
        resultCount = page.resultCount
        songIDsString = page.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    func update(with page: SearchPage, cachedAt: Date = .now) {
        query = page.query
        offset = page.offset
        limit = page.limit
        resultCount = page.resultCount
        songIDsString = page.songs.map(\.id).map(String.init).joined(separator: ",")
        self.cachedAt = cachedAt
    }

    var songIDs: [Int] {
        songIDsString
            .split(separator: ",")
            .compactMap { Int($0) }
    }
}
