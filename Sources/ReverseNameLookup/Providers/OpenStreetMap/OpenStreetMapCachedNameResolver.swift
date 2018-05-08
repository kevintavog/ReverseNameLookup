import Foundation
import SwiftyJSON

class OpenStreetMapCachedNameResolver : BaseElasticSearchCachedNameResolver {

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON {
        return try super.resolve("osm_cache", latitude, longitude, maxDistanceInMeters)
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try super.cache("osm_cache", latitude, longitude, json)
    }
}
