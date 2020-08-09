import Foundation
import NIO

struct ElasticPlacenameMsearchResponse: Codable {
    let responses: [PlacenameResponse]

    struct PlacenameResponse: Codable {
        let hits: PlacenameOuterHits

        struct PlacenameOuterHits: Codable {
            let total: Int
            let hits: [PlacenameHits]

            struct PlacenameHits: Codable {
                let _id: String
                let _source: Placename
            }
        }
    }
}

class PlacenameCache {
    let placeNameIndex = "placename_cache"

    let cacheResolver: ElasticSearchCachedNameResolver
    let eventLoop: EventLoop

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()


    init(_ eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        self.cacheResolver = ElasticSearchCachedNameResolver(eventLoop: eventLoop,indexName: placeNameIndex)

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func lookup(_ items: [BulkItemRequest], _ distance: Int) -> EventLoopFuture<[Placename?]> {
        let indexTemplate = """
        { "index": "%s" }
        """

        // Build the query
        var queryList = [String]()
        for bi in items {
            placeNameIndex.withCString {
                queryList.append(String(format: indexTemplate, $0).trimmingCharacters(in: .whitespaces))
            }
            queryList.append(cacheResolver.asQuery(bi.lat, bi.lon, distance))
        }

        return cacheResolver.msearch(queryList.joined(separator: "\n"))
            .map { data in
                if let response = try? self.decoder.decode(ElasticPlacenameMsearchResponse.self, from: data) {
                    var placenames = [Placename?]()
                    for r in response.responses {
                        if r.hits.total >= 1 {
                            placenames.append(r.hits.hits[0]._source)
                        } else {
                            placenames.append(nil)
                        }
                    }

                    return placenames
                } else {
print("Failed decoding placename msearch response")
                    return [Placename?]()
                }
            }
    }

    func save(_ placename: Placename) {
        if placename.latitude == nil || placename.longitude == nil {
            return
        }

        var pn = placename
        pn.updateForPersistence()

        if let data = try? encoder.encode(pn) {
            let id = "\(pn.location!.lat),\(pn.location!.lon)"
            cacheResolver.index(id, data)
        } else {
            print("Failed encoding placename: \(placename)")
        }
    }
}
