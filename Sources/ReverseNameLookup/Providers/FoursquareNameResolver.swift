import Foundation
import Logging
import NIO

import Just
import SwiftyJSON

class FoursquareNameResolver {
    static let logger = Logger(label: "FoursquareNameResolver")
    let baseAddress = "https://api.foursquare.com/v2/venues/search?client_id=%1$s&client_secret=%2$s&v=20180323&limit=20&llAcc=100&radius=500&ll=%3$lf%%2C+%4$lf"

    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) -> EventLoopFuture<JSON> {
        var url = ""
        Config.foursquareClientId.withCString {
            let clientId = $0
            Config.foursquareClientSecret.withCString {
                let clientSecret = $0
                url = String(format: baseAddress, clientId, clientSecret, latitude, longitude)
            }
        }

        FoursquareNameResolver.logger.info("Foursquare: \(url)")
        let promise = eventLoop.makePromise(of: JSON.self)
        Just.get(url) { response in
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
