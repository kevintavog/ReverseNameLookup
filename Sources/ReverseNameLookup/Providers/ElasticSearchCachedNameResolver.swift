import Foundation
import Logging
import NIO

import Just
import SwiftyJSON

class ElasticSearchCachedNameResolver {
    static let logger = Logger(label: "ElasticSearchCacheNameResolver")
    public let Headers = ["Content-Type": "application/json"]

    let eventLoop: EventLoop
    let indexName: String
    init(eventLoop: EventLoop, indexName: String) {
        self.eventLoop = eventLoop
        self.indexName = indexName
    }

    let searchTemplate = """
        {
            "size": 1,
            "sort": [
                {
                    "_geo_distance": {
                        "location": {
                            "lat": %1$lf,
                            "lon": %2$lf
                        },
                        "order": "asc",
                        "unit": "m"
                    }
                }
            ],
            "query": {
                "bool": {
                    "must": {
                        "match_all": {}
                    },
                    "filter": {
                        "geo_distance": {
                            "distance": "%3$ldm",
                            "location": {
                                "lat": %1$lf,
                                "lon": %2$lf
                            }
                        }
                    }
                }
            }
        }
    """


    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) -> EventLoopFuture<JSON> {
        let body = String(format: searchTemplate, latitude, longitude, maxDistanceInMeters)
        let url = "\(Config.elasticSearchUrl)/\(indexName)/entry/_search"

        let promise = eventLoop.makePromise(of: JSON.self)
        Just.post(
            url,
            headers: Headers,
            requestBody: body.data(using: .utf8, allowLossyConversion: false)!) { response in

            if response.ok {
                if let content = response.content {
                    if let json = try? JSON(data: content) {
                        let total = json["hits"]["total"].intValue
                        if total >= 1 {
                            promise.succeed(json["hits"]["hits"][0]["_source"])
                        }
                    }
                }
            }

            promise.fail(NameResolverError.NoMatches)
        }

        return promise.futureResult
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) {
        // Add a couple of book-keeping fields
        //      Track the retrieved date so items can be re-retrieved eventually.
        //      Add the location as an ElasticSearch geopoint to enable search by distance from a location
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        outputDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var jsonUpdated = json

        jsonUpdated["location"] = ["lat": latitude, "lon": longitude]
        jsonUpdated["date_retrieved"].string = outputDateFormatter.string(from: Date())

        do {
            let body = try jsonUpdated.rawData()
            let id = "\(latitude),\(longitude)"
            Just.post(
                "\(Config.elasticSearchUrl)/\(indexName)/entry/\(id)",
                requestBody: body) { response in 
                
                    if !response.ok {
                        ElasticSearchCachedNameResolver.logger.error("Caching failed: \(response)")
                    }
                }
        } catch {
            ElasticSearchCachedNameResolver.logger.error("Caching threw exception: \(error)")
        }
    }
}
