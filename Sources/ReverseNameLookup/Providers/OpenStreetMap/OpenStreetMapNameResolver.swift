import Foundation
import SwiftyJSON


class OpenStreetMapNameResolver {
    let baseAddress = "http://open.mapquestapi.com/nominatim/v1/reverse?key=%1$s&format=json&lat=%2$lf&lon=%3$lf&addressdetails=1&zoom=18&accept-language=en-us"

    let testData = """
        {
            "osm_id" : "12903132",
            "display_name" : "Space Needle, 400, Broad Street, Belltown, Seattle, King County, Washington, 98109, United States of America",
            "place_id" : "46770084",
            "lon" : "-122.349303498832",
            "address" : {
                "suburb" : "Belltown",
                "city" : "Seattle",
                "house_number" : "400",
                "road" : "Broad Street",
                "county" : "King County",
                "postcode" : "98109",
                "country" : "United States of America",
                "attraction" : "Space Needle",
                "country_code" : "us",
                "state" : "Washington"
            },
            "licence" : "Data © OpenStreetMap contributors, ODbL 1.0. ",
            "osm_type" : "way",
            "lat" : "47.6205131"
        }
    """

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
