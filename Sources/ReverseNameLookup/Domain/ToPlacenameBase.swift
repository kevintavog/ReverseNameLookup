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

    init() {
        self.init(
            Placename(sites: nil, site: nil, city: nil, state: nil, countryCode: nil, countryName: nil, fullDescription: ""),
            JSON())
    }
}

class CacheRequestData {
    let promise: EventLoopPromise<[PlacenameAndJson]>
    var namesAndJson: [PlacenameAndJson]

    init(_ promise: EventLoopPromise<[PlacenameAndJson]>, _ namesAndJson: [PlacenameAndJson]) {
        self.promise = promise
        self.namesAndJson = namesAndJson
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

        let promise = eventLoop.makePromise(of: [PlacenameAndJson].self)
        cacheResolver.msearchJson(queryList.joined(separator: "\n"))
            .whenComplete { result in
                switch result {
                    case .failure(let error):
                        promise.fail(error)
                        break
                    case .success(let jsonResponses):
                        var bulkIndex = 0
                        var jsonIndex = 0
                        var jsonCache: [(Int, ToPlacenameBase, BulkItemRequest, JSON?, Int)] = []
                        while jsonIndex < jsonResponses.count {
                            for rv in resolvers {                    
                                jsonCache.append((jsonIndex, rv, items[bulkIndex], jsonResponses[jsonIndex], distance))
                                jsonIndex += 1
                            }

                            bulkIndex += 1
                        }

                        // Resolve from the cache, if possible. Otherwise, invoke the name resolver
                        let cacheRequestData = CacheRequestData(
                            promise,
                            Array(repeating: PlacenameAndJson(), count: jsonCache.count))
                        self.doCacheRequests(jsonCache[...], cacheRequestData)
                        break
                }
            }

        return promise.futureResult
    }

    func doCacheRequests(_ remaining: ArraySlice<(Int, ToPlacenameBase, BulkItemRequest, JSON?, Int)>,
                    _ cacheRequestData: CacheRequestData) {
        var remaining = remaining
        if let first = remaining.popFirst() {
            handleCacheItem(first.1, first.2, first.3, first.4).map { [remaining] pj in
                cacheRequestData.namesAndJson[first.0] = pj
                self.doCacheRequests(remaining, cacheRequestData)
            }.whenFailure { error in
                cacheRequestData.promise.fail(error)
            }
        } else {
            return cacheRequestData.promise.succeed(cacheRequestData.namesAndJson)
        }
    }

    func handleCacheItem(_ resolver: ToPlacenameBase, _ item: BulkItemRequest, _ cachedJson: JSON?, _ distance: Int) 
                            -> EventLoopFuture<PlacenameAndJson> {
        let promise = eventLoop.makePromise(of: PlacenameAndJson.self)

        var usedCache = false
        if let validJson = cachedJson {
            if let pj = try? PlacenameAndJson(resolver.toPlacename(item.lat, item.lon, validJson), validJson) {
                usedCache = true
                promise.succeed(pj)
            }
        }

        if !usedCache {
            resolver.fromSource(item.lat, item.lon, distance)
            .whenComplete { result in 
                switch result {
                    case .failure(let error):
                        ToPlacenameBase.logger.error("Failed \(resolver.indexName) source: \(error)")
                        promise.succeed(PlacenameAndJson())
                        break
                    case .success(let json):
                        do {
                            try promise.succeed(PlacenameAndJson(
                                resolver.toPlacename(item.lat, item.lon, json),
                                json))
                            let _ = resolver.saveToCache(item.lat, item.lon, json)
                        } catch {
                            ToPlacenameBase.logger.error("Failed \(resolver.indexName) placename: \(error)")
                            promise.succeed(PlacenameAndJson())
                        }
                        break
                }
            }
        }

        return promise.futureResult
    }


    func cacheQuery(_ latitude: Double, _ longitude: Double, _ distance: Int) -> String {
        return cacheResolver.asQuery(latitude, longitude, distance)
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
