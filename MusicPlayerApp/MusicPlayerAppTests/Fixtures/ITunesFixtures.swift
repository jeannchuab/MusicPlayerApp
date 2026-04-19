import Foundation

enum ITunesFixtures {
    static let searchResponse = """
    {
      "resultCount": 2,
      "results": [
        {
          "wrapperType": "track",
          "kind": "song",
          "artistId": 909253,
          "collectionId": 120954021,
          "trackId": 120954025,
          "artistName": "Jack Johnson",
          "collectionName": "Sing-A-Longs and Lullabies",
          "trackName": "Upside Down",
          "previewUrl": "https://audio-ssl.itunes.apple.com/preview.m4a",
          "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg",
          "trackTimeMillis": 208643,
          "primaryGenreName": "Rock",
          "releaseDate": "2006-01-01T12:00:00Z",
          "trackNumber": 1,
          "trackCount": 14
        },
        {
          "wrapperType": "track",
          "kind": "song",
          "artistId": 909253,
          "collectionId": 120954021,
          "trackId": 120954026,
          "artistName": "Jack Johnson",
          "collectionName": "Sing-A-Longs and Lullabies",
          "trackName": "Broken",
          "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music/dd/ee/ff/100x100bb.jpg",
          "trackTimeMillis": 193000,
          "primaryGenreName": "Rock",
          "releaseDate": "2006-01-01T12:00:00Z",
          "trackNumber": 2,
          "trackCount": 14
        }
      ]
    }
    """

    static let albumLookupResponse = """
    {
      "resultCount": 3,
      "results": [
        {
          "wrapperType": "collection",
          "collectionType": "Album",
          "artistId": 909253,
          "collectionId": 120954021,
          "artistName": "Jack Johnson",
          "collectionName": "Sing-A-Longs and Lullabies",
          "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg"
        },
        {
          "wrapperType": "track",
          "kind": "song",
          "collectionId": 120954021,
          "trackId": 120954025,
          "artistName": "Jack Johnson",
          "collectionName": "Sing-A-Longs and Lullabies",
          "trackName": "Upside Down",
          "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg",
          "trackTimeMillis": 208643,
          "trackNumber": 1,
          "trackCount": 14
        },
        {
          "wrapperType": "track",
          "kind": "song",
          "collectionId": 120954021,
          "trackId": 120954026,
          "artistName": "Jack Johnson",
          "collectionName": "Sing-A-Longs and Lullabies",
          "trackName": "Broken",
          "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music/dd/ee/ff/100x100bb.jpg",
          "trackTimeMillis": 193000,
          "trackNumber": 2,
          "trackCount": 14
        }
      ]
    }
    """
}
