import Foundation
import SwiftyJSON


class FoursquareLocationToPlacename : ToPlacenameBase {

    let cacheResolver = FoursquareCachedNameResolver()

    override func placenameIdentifier() throws -> String {
        return "Foursquare"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func fromSource(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try FoursquareNameResolver().resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try cacheResolver.cache(latitude, longitude, json)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let rawVenues = json["response"]["venues"]
        if !rawVenues.exists() || rawVenues.count == 0 {
            throw LocationToNameInfo.Error.NoAddress("\(json)")
        }

        // Convert to an array, filter out unacceptable categories & sort by distance, ascending
        let sorted = rawVenues.map({ $0.1 })
            .filter { hasAcceptableCategories($0["categories"].array) }
            .sorted(by: { $0["location"]["distance"].intValue < $1["location"]["distance"].intValue })
// for v in sorted {
//      print("name: \(v["name"]), city: \(v["location"]["city"]), categories: \(v["categories"])")
// }

        let venue = sorted.count > 0 ? sorted[0] : rawVenues[0]
debugPrint(rawVenues)
        return Placename(
            site: getSiteName(venue),
            city: venue["location"]["city"].string,
            state: venue["location"]["state"].string,
            countryCode: venue["location"]["cc"].string,
            countryName: venue["location"]["country"].string,
            fullDescription: venue["location"]["formattedAddress"].stringValue)
    }

    func debugPrint(_ rawVenues: JSON) {
        for v in rawVenues.array! {
            let categories = v["categories"].array
            if categories == nil || categories!.count == 0 {
                print("\(v["name"]) - no categories")
            } else {
                let str = categories!.map({ $0["shortName"].stringValue }).joined(separator: ", ")
                print("\(v["name"]) - \(str)")
            }
        }
    }

    func getSiteName(_ venue: JSON) -> String? {
        if hasAcceptableCategories(venue["categories"].array) {
            return venue["name"].string
        }
        return nil
    }

    func hasAcceptableCategories(_ categories: [JSON]?) -> Bool {
        if let categories = categories {
            return categories.filter { 
                FoursquareLocationToPlacename.acceptedCategoryShortNames.contains($0["shortName"].stringValue) }
                .count > 0
        }
        return false
    }

    static private var acceptedCategoryShortNames: Set<String> = [
        "Castle",
        "Church",
        "Historic Site",
        "Hot Spring",
        "Landmark",
        "Outdoor Sculpture",
        "Scenic Lookout",
        "Sculpture",
        "Ski Area",
        "Stadium",
        "Temple",
        "Zoo"
    ]
}
