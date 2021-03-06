import Foundation
import NIO
import SwiftyJSON

class FoursquareLocationToPlacename : ToPlacenameBase {
    static let indexName = "foursquare_placenames_cache"

    init(eventLoop: EventLoop) {
        super.init(eventLoop: eventLoop, indexName: FoursquareLocationToPlacename.indexName)
    }

    static public func getCity(_ json: JSON) -> String? {
        // Return the most repeated city name of the venues within 2 km
        if let venues = FoursquareLocationToPlacename.toCompactVenues(json, maxDistance: 2000, discard: false)["list"].array {
            let nearbyCities = venues.filter { 
                $0["city"].exists() && $0["distance"].exists() && $0["distance"] < 2000 }
                .map { $0["city"].stringValue }
            let counts = nearbyCities.reduce(into: [:]) { counts, word in counts[word, default: 0] += 1}
            var maxKey = ""
            for (k,v) in counts {
                if maxKey == "" {
                    maxKey = k
                } else {
                    if v > counts[maxKey]! {
                        maxKey = k
                    }
                }
            }
            return maxKey.count > 0 ? maxKey : nil
        }
        return nil
    }

    override func placenameIdentifier() -> String {
        return "Foursquare"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: distance)
            .map { json in
                return self.postCache(json)
            }
    }

    override func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return FoursquareNameResolver(eventLoop: eventLoop).resolve(latitude, longitude, maxDistanceInMeters: distance)
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

        let venue = sorted.count > 0 ? sorted[0] : rawVenues[0]
        let site = getSiteName(venue)
        return Placename(
            sites: site == nil ? nil : [site!],
            site: site,
            city: venue["location"]["city"].string,
            state: venue["location"]["state"].string,
            countryCode: venue["location"]["cc"].string,
            countryName: venue["location"]["country"].string,
            fullDescription: venue["location"]["formattedAddress"].stringValue)
    }

    static private func toCompactVenues(_ json: JSON, maxDistance: Int, discard: Bool) -> JSON {
        let rawVenues = json["response"]["venues"]
        var response = JSON()
        if rawVenues.exists() {
            // Convert to an array & sort by distance, ascending
            let sorted = rawVenues.map({ $0.1 })
                .sorted(by: { $0["location"]["distance"].intValue < $1["location"]["distance"].intValue })
                .filter { $0["location"]["distance"].intValue < maxDistance 
                            && !(discard && FoursquareLocationToPlacename.hasDiscardableCategories($0["categories"].array)) }
            if sorted.count > 0 {
                let x = sorted.map({ venue -> [String:Any?] in
                    var categoryNames = ""
                    let venueCategories = venue["categories"].array
                    if venueCategories != nil && venueCategories!.count > 0 {
                        categoryNames = venueCategories!.map({
                            let name = $0["shortName"].stringValue
                            let accepted = FoursquareLocationToPlacename.acceptedCategoryShortNames.contains(name)
                            return name + (accepted ? "+" : "-")
                            // $0["shortName"].stringValue +
                            //     FoursquareLocationToPlacename.acceptedCategoryShortNames.contains($0["shortName"].stringValue) ? "*" : ""
                        }).joined(separator: ", ")
                    }
                    return [
                        "name": venue["name"].string,
                        "distance": venue["location"]["distance"].int,
                        "city": venue["location"]["city"].string,
                        "categories": categoryNames,
                    ]
                })
                response["list"] = JSON(x)
            }
        }
        return response
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

    static func hasDiscardableCategories(_ categories: [JSON]?) -> Bool {
        if let categories = categories {
            return categories.filter { 
                    FoursquareLocationToPlacename.discardedCategoryShortNames.contains($0["shortName"].stringValue) }
                .count > 0
        }
        return false
    }

    // From https://developer.foursquare.com/docs/resources/categories
    static private var acceptedCategoryShortNames: Set<String> = [
        "Airport",
        "Amphitheater",
        "Aquarium",
        "Castle",
        "Church",
        "Historic Site",
        "Hot Spring",
        "Landmark",
        "Memorial Site",
        "Museum",
        "Opera House",
        "Outdoor Sculpture",
        "Palace",
        "Scenic Lookout",
        "Sculpture",
        "Ski Area",
        "Spiritual Center",
        "Stadium",
        "Train Station",
        "Zoo"
    ]

    // These have been deemed 'never of interest' and are filtered out
    static private var discardedCategoryShortNames: Set<String> = [
        "Arcade", "Bowling Alley", "Casino", "Circus", "Comedy Club", 
        "Bus", "Bus Station", "Bus Stop", "Coffee Shop", "Pharmacy", "Noodles", "Automotive",
        "Café", "Korean", "Sandwiches", "Thai",
        "Government", "Office", "Post Office", "Real Estate", "Shipping Store", "Tech Startup"
    ]
}
