import Foundation
import SwiftyJSON


class OpenCageDataNameResolver {
    let baseAddress = "https://api.opencagedata.com/geocode/v1/json?key=%1$s&no_annotations=1&q=%2$lf,%3$lf"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        var url = ""
        Config.openCageDataLookupKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

        guard let data = try synchronousHttpGet(url) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}
