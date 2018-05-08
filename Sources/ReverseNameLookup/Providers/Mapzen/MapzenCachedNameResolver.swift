import Foundation
import SwiftyJSON

class MapzenCachedNameResolver : BaseElasticSearchCachedNameResolver {

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON {
        return try super.resolve("mapzen_placenames_cache", latitude, longitude, maxDistanceInMeters)
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try super.cache("mapzen_placenames_cache", latitude, longitude, json)
    }
}
