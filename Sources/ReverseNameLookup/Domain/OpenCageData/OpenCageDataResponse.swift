import Foundation


struct OpenCageDataResponse : Codable {
    var location: ReverseNameLocation?
    var date_retrieved: String?

    var results: [OpenCageDataResults]?
}

struct OpenCageDataResults : Codable {
    var confidence: Int?
    var formatted: String?

    struct Components : Codable {
        var city: String?
        var city_distrct: String?
        var country: String?
        var country_code: String?
        var postcode: String?
        var road: String?
        var state: String?
        var state_code: String?
        var suburb: String?
        var unknown: String?

        var attraction: String?
    }
    var components: Components?

    struct Geometry : Codable {
        var lat: Double?
        var lon: Double?
    }
    var geometry: Geometry?
}

