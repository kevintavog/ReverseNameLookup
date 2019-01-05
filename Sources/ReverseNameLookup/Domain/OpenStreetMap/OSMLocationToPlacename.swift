import Foundation
import SwiftyJSON

class OSMLocationToPlacename : ToPlacenameBase {

    let cacheResolver = OpenStreetMapCachedNameResolver()

    override func placenameIdentifier() throws -> String {
        return "OpenStreetMap"
    }

    override func fromCache(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try cacheResolver.resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func fromSource(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        return try OpenStreetMapNameResolver().resolve(latitude, longitude, maxDistanceInMeters: 3)
    }

    override func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        try cacheResolver.cache(latitude, longitude, json)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let locationNameInfo = try osmToInfo(json, latitude, longitude)

        let site = siteName(locationNameInfo.address)
        var city = cityName(locationNameInfo.address)
        let state = stateName(locationNameInfo.address)
        let country = countryName(locationNameInfo.address)

        if site == city {
            city = nil
        }

        return Placename(
            sites: site == nil ? nil : [site!],
            site: site,
            city: city,
            state: state,
            countryCode: locationNameInfo.address.country_code,
            countryName: country,
            fullDescription: json["display_name"].stringValue)
    }

    func osmToInfo(_ json: JSON, _ latitude: Double, _ longitude: Double) throws -> OSMLocationNameInfo {
        if !json["address"].exists() {
            throw LocationToNameInfo.Error.NoAddress("\(json)")            
        }

        let jsonAddress = json["address"]
        if jsonAddress.exists() {
            var address = OSMAddress()
            address.artwork = jsonAddress["artwork"].string
            address.attraction = jsonAddress["attraction"].string
            address.archaeological_site = jsonAddress["archaeological_site"].string
            address.garden = jsonAddress["garden"].string
            address.library = jsonAddress["library"].string
            address.memorial = jsonAddress["memorial"].string
            address.monument = jsonAddress["monument"].string
            address.museum = jsonAddress["museum"].string
            address.nature_reserve = jsonAddress["nature_reserve"].string
            address.park = jsonAddress["park"].string
            address.place_of_worship = jsonAddress["place_of_worship"].string
            address.school = jsonAddress["school"].string
            address.sports_centre = jsonAddress["sports_centre"].string
            address.stadium = jsonAddress["stadium"].string
            address.viewpoint = jsonAddress["viewpoint"].string
            address.zoo = jsonAddress["zoo"].string


            address.suburb = jsonAddress["suburb"].string
            address.neighbourhood = jsonAddress["neighbourhood"].string
            address.village = jsonAddress["village"].string
            address.hamlet = jsonAddress["hamlet"].string
            address.town = jsonAddress["town"].string
            address.locality = jsonAddress["locality"].string
            address.city = jsonAddress["city"].string
            address.city_district = jsonAddress["city_district"].string
            address.postcode = jsonAddress["postcode"].string
            address.county = jsonAddress["county"].string
            address.state = jsonAddress["state"].string
            address.state_district = jsonAddress["state_district"].string
            address.country_code = jsonAddress["country_code"].string
            address.country = jsonAddress["country"].string

            return OSMLocationNameInfo(
                latitude: latitude,
                longitude: longitude,
                address: address)
        }

        throw LocationToNameInfo.Error.NoLatLon("\(json)")            
    }

    func countryName(_ addressInfo: OSMAddress) -> String? {
        guard let countryCode = countryCodeForDescription(addressInfo) else {
            return nil
        }

        var countryName = CountryCodeConverter.toName(code: countryCode)
        if countryName == nil {
            countryName = addressInfo.country ?? addressInfo.country_code
        }

        return countryName
    }

    func countryCodeForDescription(_ addressInfo: OSMAddress) -> String? {
        guard let countryCode = addressInfo.country_code else {
            return addressInfo.country_code
        }

        switch countryCode {
            case "gb", "us":
                return nil
            default:
                return addressInfo.country_code
        }
    }

    func stateName(_ addressInfo: OSMAddress) -> String? {
        // Some state information is unnecessary
        if let countryCode = addressInfo.country_code {
            if !OSMLocationToPlacename.supportsState.contains(countryCode.uppercased()) {
                return nil
            }
        }

        return StateNameConverter.toName(addressInfo)
    }

    func cityName(_ addressInfo: OSMAddress) -> String? {

        // Use the shorter version of these - it can make a big difference for Brussels
        if addressInfo.country_code ?? "" == "be" {
            if let city = addressInfo.city, let cityDistrict = addressInfo.city_district {
                return city.utf8.count < cityDistrict.utf8.count ? city : cityDistrict
            }
        }

        // The city name is the first of these components, none to many may exist
        let cityComponents = [
            addressInfo.city, 
            addressInfo.city_district,
            addressInfo.town,
            addressInfo.neighbourhood,
            addressInfo.suburb,
            addressInfo.village,
            addressInfo.county
        ]
        return cityComponents.compactMap({ $0 }).first
    }

    func siteName(_ addressInfo: OSMAddress) -> String? {
        // The site name is the first of these components, none to many may exist
        let siteComponents = [
            addressInfo.attraction,
            addressInfo.archaeological_site,
            addressInfo.garden,
            addressInfo.library,
            addressInfo.monument,
            addressInfo.museum,
            addressInfo.place_of_worship,
            addressInfo.stadium,
            addressInfo.viewpoint,
            addressInfo.zoo,

            addressInfo.memorial,

            addressInfo.nature_reserve,
        ]
        return siteComponents.compactMap({ $0 }).first
    }


    static private var supportsState: Set<String> = ["CA", "GB", "US"]
}