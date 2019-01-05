import Foundation
import SwiftyJSON

class ElasticSearchCachedNameResolver {

    let indexName: String
    init(indexName: String) {
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


    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON {
        let body = String(format: searchTemplate, latitude, longitude, maxDistanceInMeters)
        let url = "\(Config.elasticSearchUrl)/\(indexName)/entry/_search"
        guard let data = try synchronousHttpPost(url, body) else {
            throw NameResolverError.NoDataReturned
        }

        let json = try JSON(data: data)
        let total = json["hits"]["total"].intValue
        if total < 1 {
            throw NameResolverError.NoMatches
        }

        return json["hits"]["hits"][0]["_source"]
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        // Add a couple of book-keeping fields
        //      Track the retrieved date so items can be re-retrieved eventually.
        //      Add the location as an ElasticSearch geopoint to enable search by distance from a location
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        outputDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        var jsonUpdated = json

        jsonUpdated["location"] = ["lat": latitude, "lon": longitude]
        jsonUpdated["date_retrieved"].string = outputDateFormatter.string(from: Date())

        let body = jsonUpdated.rawString()!
        let id = "\(latitude),\(longitude)"
        _ = try synchronousHttpPost("\(Config.elasticSearchUrl)/\(indexName)/entry/\(id)", body)
    }

}