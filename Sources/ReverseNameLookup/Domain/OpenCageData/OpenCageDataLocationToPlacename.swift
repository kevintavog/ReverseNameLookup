import Foundation
import SwiftyJSON


class OpenCageDataLocationToPlacename : ToPlacenameBase{

    let cacheResolver = OpenCageDataCachedNameResolver()

    override func placenameIdentifier() throws -> String {
        return "OpenCageData"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func fromSource(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try OpenCageDataNameResolver().resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try cacheResolver.cache(latitude, longitude, json)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let components = json["results"][0]["components"]
        if !components.exists() {
            throw LocationToNameInfo.Error.NoAddress("\(json)")
        }

        return Placename(
            site: nil,
            city: components["city"].string,
            state: components["state_code"].string,
            countryCode: components["country_code"].string,
            countryName: components["country"].string,
            fullDescription: json["results"][0]["formatted"].stringValue)
    }
}