import Foundation
import SwiftyJSON

class OpenCageDataCachedNameResolver : BaseElasticSearchCachedNameResolver {

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON {
        return try super.resolve("opencagedata_placenames_cache", latitude, longitude, maxDistanceInMeters)
    }

    func cache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try super.cache("opencagedata_placenames_cache", latitude, longitude, json)
    }
}
