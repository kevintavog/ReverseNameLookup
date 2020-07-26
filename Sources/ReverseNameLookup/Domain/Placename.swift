import Foundation

import Vapor

struct Placename: Content {
    let description: String
    let fullDescription: String
    let sites: [String]?
    let site: String?
    let city: String?
    let state: String?
    let countryCode: String?
    let countryName: String?
    var latitude: Double?
    var longitude: Double?

    public init(sites: [String]?, site: String?, city: String?, state: String?, countryCode: String?, countryName: String?, fullDescription: String) {
        self.sites = sites
        self.site = site
        self.city = city
        self.state = state
        self.countryCode = countryCode
        self.countryName = countryName
        self.fullDescription = fullDescription

        let nameComponents = [
            site,
            city, 
            state, 
            countryName]
        self.description = nameComponents.compactMap( { $0 }).joined(separator: ", ")
    }
}

struct BulkItemRequest: Content {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

struct BulkItemResponse: Content {
    let placename: Placename?
    let error: String?

    init(_ placename: Placename?, _ error: String?) {
        self.placename = placename
        self.error = error
    }
}
