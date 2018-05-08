import Foundation
import SwiftyJSON


class MapzenLocationToPlacename: ToPlacenameBase {

    let cacheResolver = MapzenCachedNameResolver()

    override func placenameIdentifier() throws -> String {
        return "Mapzen"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func fromSource(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try MapzenNameResolver().resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try cacheResolver.cache(latitude, longitude, json)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let properties = json["features"][0]["properties"]
        if !properties.exists() {
            throw LocationToNameInfo.Error.NoAddress("\(json)")
        }

        let city = cityName(properties)

        return Placename(
            site: nil,
            city: city,
            state: properties["region_a"].string,
            countryCode: properties["country_a"].string,
            countryName: properties["country"].string,
            fullDescription: properties["label"].stringValue)
    }

    func cityName(_ properties: JSON) -> String? {

// Possibly only include if the value is part of 'label'...
        // The city name is the first of these components, none to many may exist
        let cityComponents = [
            properties["city"].string,
            properties["locality"].string,
            properties["localadmin"].string
        ]
        return cityComponents.flatMap({ $0 }).first
    }
}