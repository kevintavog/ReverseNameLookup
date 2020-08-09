import Foundation
import NIO
import Logging

import Just
import SwiftyJSON

// For rate limit status, see
//      http://overpass-api.de/api/status

class OverpassNameResolver {
    static let logger = Logger(label: "OverpassNameResolver")
    let baseAddress = "http://overpass-api.de/api/interpreter"
    let Headers = ["Content-Type": "application/json"]

    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) -> EventLoopFuture<JSON> {
        // In order to get bounding boxes for the areas, a geom is provided that includes about a 7x8 km area
        // https://en.wikipedia.org/wiki/Decimal_degrees
        let latDelta = 0.1
        let lonDelta = 0.2
        let minLat = latitude - latDelta
        let maxLat = latitude + latDelta
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta
        let query = "[timeout:7][out:json];is_in(\(latitude),\(longitude))->.a;way(pivot.a);out tags geom(\(minLat),\(minLon),\(maxLat),\(maxLon));out bb ids;relation(pivot.a);out tags bb;"

        OverpassNameResolver.logger.info("Overpass: \(query)")
        let promise = eventLoop.makePromise(of: JSON.self)
        Just.post(
            baseAddress, 
            requestBody: query.data(using: .utf8, allowLossyConversion: false)!) { response in

            if response.ok {
                if let content = response.content {
                    if let json = try? JSON(data: content) {
                        promise.succeed(json)
                    }
                }
            }
            promise.fail(NameResolverError.NoDataReturned)
        }

        return promise.futureResult
    }
}
