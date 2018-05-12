import Foundation
import SwiftyJSON

class FoursquareCachedNameResolver : BaseElasticSearchCachedNameResolver {

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON {
        return try super.resolve("foursquare_placenames_cache", latitude, longitude, maxDistanceInMeters)
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try super.cache("foursquare_placenames_cache", latitude, longitude, json)
    }
}
