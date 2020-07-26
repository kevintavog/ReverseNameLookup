import Foundation
import NIO
import Logging

import SwiftyJSON

struct PlacenameAndJson {
    let placename: Placename
    let json: JSON

    init(_ placename: Placename, _ json: JSON) {
        self.placename = placename
        self.json = json
    }
}

class ToPlacenameBase {
    static let logger = Logger(label: "ToPlacenameBase")

    let cacheResolver: ElasticSearchCachedNameResolver
    let eventLoop: EventLoop
    let indexName: String

    init(eventLoop: EventLoop, indexName: String) {
        self.eventLoop = eventLoop
        self.indexName = indexName
        self.cacheResolver = ElasticSearchCachedNameResolver(eventLoop: eventLoop,indexName: indexName)
    }

    func from(latitude: Double, longitude: Double, distance: Int, cacheOnly: Bool = false) -> EventLoopFuture<PlacenameAndJson> {
        return fromCache(latitude, longitude, distance)
            .flatMapError { err in
                if !cacheOnly, case NameResolverError.NoMatches = err {
                    return self.fromSource(latitude, longitude, distance)
                        .flatMap { json in
                            self.saveToCache(latitude, longitude, json)
                            return self.eventLoop.makeSucceededFuture(json)
                        }
                } else {
                    ToPlacenameBase.logger.error("cache error: \(err)")
                    return self.eventLoop.makeFailedFuture(err)
                }
            }
            .flatMap { json in
                return self.convert(latitude, longitude, json)
            }
    }

    func convert(_ latitude: Double, _ longitude: Double, _ json: JSON) -> EventLoopFuture<PlacenameAndJson> {
        do {
            return try eventLoop.makeSucceededFuture(
                PlacenameAndJson(toPlacename(latitude, longitude, json), json))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    func placenameIdentifier() -> String {
        return "'placenameIdentifier' is not implemented in the derived class"
    }

    func postCache(_ json: JSON) -> JSON {        
        return json
    }

    func bulk(_ items: [BulkItemRequest], _ resolvers: [ToPlacenameBase], _ distance: Int) -> EventLoopFuture<[PlacenameAndJson]> {
        let indexTemplate = """
        { "index": "%s" }
        """

        // Build the query (array of strings)
        var queryList = [String]()
        for bi in items {
            for rv in resolvers {
                rv.indexName.withCString {
                    queryList.append(String(format: indexTemplate, $0).trimmingCharacters(in: .whitespaces))
                }
                queryList.append(rv.cacheQuery(bi.lat, bi.lon, distance))
            }
        }

        return cacheResolver.msearch(queryList.joined(separator: "\n"))
            .map { jsonResponses in
                // Convert each response to PlacenameAndJson
                var namesAndJson: [PlacenameAndJson] = []
                var bulkIndex = 0
                var jsonIndex = 0
                while jsonIndex < jsonResponses.count {
                    for rv in resolvers {
                        let js = jsonResponses[jsonIndex]
                        var addedItem = false
                        if let validJson = js {
                            // let postCacheJson = rv.postCache(validJson)
                            do {
                                let bi = items[bulkIndex]
                                try namesAndJson.append(PlacenameAndJson(
                                    rv.toPlacename(bi.lat, bi.lon, validJson),
                                    validJson))
                                addedItem = true
                            } catch {
// print("error: \(error)")
                                // Ignore, an empty will be added
                            }
                        }
                        
                        if !addedItem {
                            namesAndJson.append(PlacenameAndJson(
                                Placename(sites: nil, site: nil, city: nil, state: nil, countryCode: nil, countryName: nil, fullDescription: ""),
                                JSON()
                            ))                      
                        }

                        jsonIndex += 1
                    }

                    bulkIndex += 1
                }

                return namesAndJson
            }
    }

    func cacheQuery(_ latitude: Double, _ longitude: Double, _ distance: Int) -> String {
        return cacheResolver.asQuery(latitude, longitude, maxDistanceInMeters: distance)
    }

    func fromCache(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: distance)
            .map { json in
                return self.postCache(json)
            }
    }

    func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) {
        cacheResolver.cache(latitude, longitude, json)
    }

    func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return eventLoop.makeFailedFuture(
            LocationToNameInfo.Error.NotImplemented("'fromSource' is not implemented in the derived class"))
    }

    func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        throw LocationToNameInfo.Error.NotImplemented("'toPlacename' is not implemented in the derived class")
    }
}
