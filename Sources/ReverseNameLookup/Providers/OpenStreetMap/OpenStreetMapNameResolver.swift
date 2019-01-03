import Foundation
import SwiftyJSON


class OpenStreetMapNameResolver {
    let baseAddress = "http://open.mapquestapi.com/nominatim/v1/reverse?key=%1$s&format=json&lat=%2$lf&lon=%3$lf&addressdetails=1&zoom=20&accept-language=en-us"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        var url = ""
        Config.mapquestLookupKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

        guard let data = try synchronousHttpGet(url) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}
