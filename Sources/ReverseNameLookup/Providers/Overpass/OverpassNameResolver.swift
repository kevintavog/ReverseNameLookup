import Foundation
import SwiftyJSON


class OverpassNameResolver {
    let baseAddress = "http://overpass-api.de/api/interpreter"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        // In order to get bounding boxes for the areas, a geom is provided that includes about a 7x8 km area
        // https://en.wikipedia.org/wiki/Decimal_degrees
        let latDelta = 0.1
        let lonDelta = 0.2
        let minLat = latitude - latDelta
        let maxLat = latitude + latDelta
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta
        let query = "[timeout:7][out:json];is_in(\(latitude),\(longitude))->.a;way(pivot.a);out tags geom(\(minLat),\(minLon),\(maxLat),\(maxLon));out bb ids;relation(pivot.a);out tags bb;"
        guard let data = try synchronousPlainHttpPost(baseAddress, query) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}
