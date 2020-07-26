import Foundation
import Logging
import NIO
import SwiftyJSON

struct SiteInfo {
    let name: String
    let area: Double

    public init(name: String, minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) {
        self.name = name
        self.area = Distance.areaOf(minLat, minLon, maxLat, maxLon)
    }
}

class OverpassLocationToPlacename : ToPlacenameBase{
    static let indexName = "overpass_placenames_cache"
    let logDiagnostics = false

    init(eventLoop: EventLoop) {
        super.init(eventLoop: eventLoop, indexName: OverpassLocationToPlacename.indexName)
    }

    override func placenameIdentifier() -> String {
        return "Overpass"
    }

    override func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return OverpassNameResolver(eventLoop: eventLoop)
            .resolve(latitude, longitude, maxDistanceInMeters: distance)
            .flatMap { json in
                return self.eventLoop.makeSucceededFuture(self.filterResponse(json))
            }
    }

    func isUsableAdmin(_ json: JSON) -> Bool {
        if json["tags"]["admin_level"].exists() {
            if json["tags"]["admin_level"].stringValue == "2" {
                return json["tags"]["ISO3166-1:alpha2"].exists()
            }
            return true
        }

        return false
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        // The country code is needed in order to figure out state & city
        let adminElements = json["elements"].array?.filter( { isUsableAdmin($0) })
            .sorted(by: { Int($0["tags"]["admin_level"].stringValue)! < Int($1["tags"]["admin_level"].stringValue)! } )

        if  adminElements != nil && adminElements!.count > 0 {
            if let countryElement = adminElements?.filter( { $0["tags"]["admin_level"].string == "2" } ) {
                if let countryCode = countryElement[0]["tags"]["ISO3166-1:alpha2"].string ?? 
                        countryElement[0]["tags"]["ISO3166-1"].string {
diagnostic("country: \(countryCode)")

for e in adminElements! {
    diagnostic("adminLevel: \(e["tags"]["admin_level"]); \(e["tags"]["name"]) (\(e["tags"]["name:en"])) -- \(e["tags"]["type"]) - \(e["tags"]["place"])")
}

                    var countryName = countryElement[0]["tags"]["name:en"].string ?? countryElement[0]["tags"]["name"].string
                    if let shortCountryName = CountryCodeConverter.toName(code: countryCode) {
                        countryName = shortCountryName
                    }
                    if countryCode == "US" {
                        countryName = nil
                    }

                    let state = StateNameConverter.toName(countryCode, getState(countryCode, json))
                    let city = getCity(countryCode, state, adminElements)
                    let sites = getSites(json)
                    let smallestSite = sites.first?.name ?? nil

                    var components = [city, state, countryName]
                    components.insert(contentsOf: sites.map { $0.name }, at: 0)

                    return Placename(
                        sites: sites.count == 0 ? nil : sites.map { $0.name },
                        site: smallestSite,
                        city: city,
                        state: state,
                        countryCode: countryCode,
                        countryName: countryName,
                        fullDescription: components.compactMap({$0}).joined(separator: ", ") )
                }
            }
        }

        return Placename(
            sites: nil,
            site: nil,
            city: nil,
            state: nil,
            countryCode: nil,
            countryName: nil,
            fullDescription: "")
    }

    func getState(_ countryCode: String, _ json: JSON) -> String? {
        var adminOrder = ["4"]
        switch countryCode {
            case "CA", "GB", "MX", "US":
                break;
            default:
                adminOrder = []
                break;
        }

        for desiredLevel in adminOrder {
            for (_, itemJson):(String, JSON) in json["elements"] {
                if let adminLevel = itemJson["tags"]["admin_level"].string {
                    if adminLevel == desiredLevel {
                        let name = itemJson["tags"]["name:en"].string ?? itemJson["tags"]["name"].string
                        if name != nil {
                            return name!
                        }
                    }
                }
            }
        }
        return nil
    }

    func getCity(_ countryCode: String, _ state: String?, _ adminJson: [JSON]?) -> String? {
        if adminJson == nil {
            return nil
        }

        var placeTypes = [String: [String]]()
        var adminOrder: [String] = []
        switch countryCode {
            case "BE":
                adminOrder = ["9"];
                break
            case "CA":
                adminOrder = ["8", "10", "6", "5"]
                break
            case "DE":
                adminOrder = ["6", "4"]
            case "GB":
                if state == "Scotland" {
                    adminOrder = ["6", "8", "10"]
                } else {
                    adminOrder = ["10", "6"]
                    placeTypes["6"] = ["city"]
                }
                break;
            case "IS":
                adminOrder = ["6"]
            case "MX":
                adminOrder = ["8", "10"]
                break
            case "US":
                adminOrder = ["8", "10", "6", "5"]
                for a in adminOrder {
                    placeTypes[a] = ["city", "town"]
                }
            default:
                adminOrder = ["8"]
                break;
        }

        let borderTypes: [String]? = countryCode == "US" ? ["city", "locality", "town"] : nil
        for desiredLevel in adminOrder {
            for itemJson in adminJson! {
                if let adminLevel = itemJson["tags"]["admin_level"].string {
                    if adminLevel == desiredLevel {
                        let name = itemJson["tags"]["name:en"].string ?? itemJson["tags"]["name"].string
                        if name != nil {
                            if let designation = itemJson["tags"]["designation"].string {
                                if designation == "civil_parish" && !itemJson["tags"]["council_style"].exists() {
                                    continue
                                }
                            }
                            if let placeRequirements = placeTypes[adminLevel] {
                                if let place = itemJson["tags"]["place"].string, placeRequirements.contains(place) {
                                    return name
                                }
                            } else {
                                return name
                            }
                            if borderTypes != nil {
                                if let border = itemJson["tags"]["border_type"].string, borderTypes!.contains(border) {
                                    return name
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    func getSites(_ json: JSON) -> [SiteInfo] {
        var sites = [SiteInfo]()
        for (_, itemJson):(String, JSON) in json["elements"] {

            if let name = itemJson["tags"]["name:en"].string ?? itemJson["tags"]["name"].string {
                var shortName = name
                if (itemJson["tags"]["amenity"].string ?? "") == "university" {
                    shortName = itemJson["tags"]["short_name"].string ?? name
                }
                if isSite(itemJson) {
                    let si = SiteInfo(
                        name: shortName,
                        minLat: itemJson["bounds"]["minlat"].doubleValue, minLon: itemJson["bounds"]["minlon"].doubleValue,
                        maxLat: itemJson["bounds"]["maxlat"].doubleValue, maxLon: itemJson["bounds"]["maxlon"].doubleValue)
// diagnostic("'\(si.name): \(si.area)'")
                    if !sites.contains(where: { $0.name == si.name }) {
                        sites.append(si)
                    }
                }
            }
        }

        return sites.sorted(by: { $0.area < $1.area })
    }

    func isSite(_ json: JSON) -> Bool {
        var site = false
        let elementType = json["type"].string ?? ""
        let tourism = json["tags"]["tourism"].string ?? ""
        if !tourism.isEmpty && tourism != "hotel" {
            site = true
        }

        if !site && json["tags"]["leisure"].exists() {
            site = true
        }

        if !site && json["tags"]["historic"].exists() {
            if elementType != "relation" || json["tags"]["building"].exists() {
                if tourism != "hotel" {
                    site = true
                }
            }
        }

        if !site, let amenity = json["tags"]["amenity"].string {
            switch amenity {
                case "conference_centre", "grave_yard", "library", "marketplace", 
                  "place_of_worship", "research_institute", "university":
                    site = true
                    break

                // A few types of amenities short-circuit checks; there's no need showing these
                case "restaurant":
                    return false
                default:
                    break
            }
        }

        if !site, let landuse = json["tags"]["landuse"].string {
            if landuse == "cemetery" || landuse == "conservation" {
                site = true
            }
        }

        if !site, let place = json["tags"]["place"].string {
            if place == "square" {
                site = true
            }
        }

        if !site, let boundary = json["tags"]["boundary"].string {
            if boundary == "national_park" || boundary == "protected_area" {
                site = true
            }
        }

        if !site && json["tags"]["railway"].exists() {
            site = true
        }

        if !site, let manMade = json["tags"]["man_made"].string {
            site = manMade == "pier"
        }

        if !site, let aeroway = json["tags"]["aeroway"].string {
            site = aeroway == "aerodrome"
        }

        // If it doesn't have bounds, we can't use it (to determine the smallest of the sites)
        if site && (!json["bounds"]["minlat"].exists() || !json["bounds"]["minlon"].exists() ||
            !json["bounds"]["maxlat"].exists() || !json["bounds"]["maxlon"].exists()) {
                OverpassLocationToPlacename.logger.warning("no bounds for \(json)")
                return false
        }

        if !site {
            if !json["tags"]["admin_level"].exists() && json["tags"]["place"] != "island" {
                var showPotentialSite = true
                if let boundary = json["tags"]["boundary"].string {
                    switch boundary {
                        case "ceremonial", "land_area", "police", "political", "timezone", "traditional":
                            showPotentialSite = false
                            break
                        default:
                            break
                    }
                }
                if showPotentialSite {
diagnostic("site name?: \(json["tags"]["name"]) (\(json["tags"]["name:en"])); building=\(json["tags"]["building"]) - [\(json["id"])]")
                }
            }
        }

        return site
    }

/*
// temp method for testing/development
static func filterFile(_ filename: String) throws {
    do {
        let contents = try Data(contentsOf: URL(fileURLWithPath: filename))
        let inJson = try JSON(data: contents)
// Logger.log("input: \(inJson)")
        let outJson = OverpassLocationToPlacename().filterResponse(inJson)
Logger.log("output: \(outJson)")
    }
}
*/

    // The Overpass response is huge, with many tags that aren't useful to us - filter those out.
    func filterResponse(_ json: JSON) -> JSON {
        var filteredJson = JSON()
        for (key, keyJson):(String, JSON) in json {
            if !isIgnoredKey(key) {
                if let _ = keyJson.array {
                    var items = [JSON]()
                    for (_, indexJson):(String, JSON) in keyJson {
                        items.append(filterResponse(indexJson))
                    }
                    filteredJson[key].arrayObject = items
                } else if let _ = keyJson.dictionary {
                    filteredJson[key] = filterResponse(keyJson)
                } else {
                    filteredJson[key] = keyJson
                }
            }
        }

        return filteredJson
    }

    func isIgnoredKey(_ key: String) -> Bool {
        if key.starts(with: "name:") && key != "name:en" { return true }
        if key.starts(with: "alt_name:") && key != "alt_name:en" { return true }
        if key.starts(with: "official_name:") && key != "official_name:en" { return true }
        if key.starts(with: "old_name:") && key != "old_name:en" { return true }
        if key.starts(with: "old_short_name:") && key != "old_short_name:en" { return true }
        if key.starts(with: "short_name:") && key != "short_name:en" { return true }
        if key == "geometry" { return true }
        return false
    }

    func diagnostic(_ msg: String) {
        if logDiagnostics {
            OverpassLocationToPlacename.logger.info("\(msg)")
        }
    }
}