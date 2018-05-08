import Foundation
import SwiftyJSON


class MapzenNameResolver {
    let baseAddress = "https://search.mapzen.com/v1/reverse?api_key=%1$s&size=5&point.lat=%2$lf&point.lon=%3$lf"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        var url = ""
        Config.mapzenLookupKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

        guard let data = try synchronousHttpGet(url) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}
