import Foundation
import SwiftyJSON


class FoursquareNameResolver {
    let baseAddress = "https://api.foursquare.com/v2/venues/search?client_id=%1$s&client_secret=%2$s&v=20180323&limit=10&llAcc=10&radius=500&ll=%3$lf%%2C+%4$lf"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        var url = ""
        Config.foursquareClientId.withCString {
            let clientId = $0
            Config.foursquareClientSecret.withCString {
                let clientSecret = $0
                url = String(format: baseAddress, clientId, clientSecret, latitude, longitude)
            }
        }

print("foursquare url: '\(url)'")
        guard let data = try synchronousHttpGet(url) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}

/*
Default elastic search settings for the map cache

{
    "settings": {
      "index": {
        "number_of_shards": "1",
        "number_of_replicas": "0"
      }
    },
    "mappings": {
      "entry": {
        "properties": {
          "date_retrieved": {
            "type": "date"
          },
          "location": {
            "type": "geo_point"
          }
        }
      }
    }
}


*/