import Foundation


struct MapzenResponse : Codable {
    var location: ReverseNameLocation?
    var date_retrieved: String?

    var features: [MapzenFeatures]?
}

struct MapzenFeatures : Codable {
    var properties: MapzenProperties?
}

struct MapzenProperties : Codable {
    var source: String?
    var neighbourhood_grid: String?
    var country: String?
    var region: String?
    var street: String?
    var housenumber: String?
    var region_a: String?
    var layer: String?
    var name: String?
    var source_id: String?
    var accuracy: String?
    var id: String?
    var confidence: Double?
    var label: String?
    var distance: Double?
    var postalcode: String?
    var neighbourhood: String?
    var county: String?
    var country_a: String?
    var locality: String?
}
