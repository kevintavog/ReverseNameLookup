import Foundation


struct OSMResponse : Codable {
    var location: ReverseNameLocation?
    var date_retrieved: String?

    var osm_id: String?
    var display_name: String?
    var place_id: String?
    var lon: String?
    var address: OSMAddress?
    var lat: String?
    var error: String?
}

struct OSMAddress : Codable {
    var artwork: String?
    var attraction: String?
    var archaeological_site: String?
    var garden: String?
    var library: String?
    var memorial: String?
    var monument: String?
    var museum: String?
    var nature_reserve: String?
    var park: String?
    var place_of_worship: String?
    var school: String?
    var sports_centre: String?
    var stadium: String?
    var viewpoint: String?
    var zoo: String?


    var suburb: String?
    var neighbourhood: String?
    var village: String?
    var hamlet: String?
    var town: String?
    var locality: String?
    var city: String?
    var city_district : String?
    var postcode: String?
    var county: String?
    var state: String?
    var state_district: String?
    var country_code: String?
    var country: String?    
}

