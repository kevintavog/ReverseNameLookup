import Foundation
import NIO
import Logging

import Just
import SwiftyJSON

class AzureNameResolver {
    static let logger = Logger(label: "AzureNameResolver")
    let baseAddress = "https://atlas.microsoft.com/search/address/reverse/json?subscription-key=%1$s&api-version=1.0&query=%2$lf,%3$lf&radius=500&language=en-US"

    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) -> EventLoopFuture<JSON> {
        var url = ""
        Config.azureSubscriptionKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

        AzureNameResolver.logger.info("Azure: \(url)")
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
