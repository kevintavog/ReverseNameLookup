import Foundation
import NIO
import SwiftyJSON

class AzureLocationToPlacename: ToPlacenameBase {
    let cacheResolver:  ElasticSearchCachedNameResolver

    override init(eventLoop: EventLoop) {
        cacheResolver = ElasticSearchCachedNameResolver(
            eventLoop: eventLoop, indexName: "azure_placenames_cache")

        super.init(eventLoop: eventLoop)
    }

    override func placenameIdentifier() -> String {
        return "Azure"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: distance)
    }

    override func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return AzureNameResolver(eventLoop: eventLoop).resolve(latitude, longitude, maxDistanceInMeters: distance)
    }

    override func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) {
        cacheResolver.cache(latitude, longitude, json)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let firstAddress = json["addresses"][0]["address"]
        if !firstAddress.exists() {
            throw LocationToNameInfo.Error.NoAddress("\(json)")
        }

        var distance: Double? = nil
        let position = json["addresses"][0]["position"]
        if position.exists() {
            // Position is a string with two doubles, comma separated: 47.620163,-122.349304
            let tokens = position.stringValue.split(separator: ",")
            if tokens.count == 2 {
                if  let lat = Double(tokens[0]), let lon = Double(tokens[1]) {
                    distance = Distance.metersBetween(latitude, longitude, lat, lon)
                }
            }
        }

        var city: String? = nil
        if distance != nil && distance! < 2000 {
            if let c = firstAddress["municipality"].string {
                if c.contains(",") {

                } else {
                    city = c
                }
            }
        }

        return Placename(
            sites: nil,
            site: nil,
            city: city,
            state: firstAddress["countrySubdivision"].string,
            countryCode: firstAddress["countryCode"].string,
            countryName: firstAddress["country"].string,
            fullDescription: firstAddress["freeformAddress"].stringValue)
    }
}