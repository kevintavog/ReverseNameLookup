import Foundation
import NIO

import Just
import SwiftyJSON

class OpenCageDataNameResolver {
    let baseAddress = "https://api.opencagedata.com/geocode/v1/json?key=%1$s&no_annotations=1&q=%2$lf,%3$lf"

    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) -> EventLoopFuture<JSON> {
        var url = ""
        Config.openCageDataLookupKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

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
