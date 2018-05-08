import Foundation
import Async
import SwiftyJSON

class LocationToNameInfo {

    enum Error : Swift.Error {
        case NoMatches
        case NoDataInResponse
        case NoLatLon(String)
        case NoAddress(String)
        case NotImplemented(String)
    }


    func from(latitude: Double, longitude: Double) throws -> Placename {
        var osmJson = JSON()
        var mapzenJson = JSON()
        var openCageDataJson = JSON()


        let calls = AsyncGroup()
        calls.background {
            do {
                (_, osmJson) = try OSMLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
print("osm error: \(error)")
            }
        }

        calls.background {
            do {
                (_, mapzenJson) = try MapzenLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
print("mapzen error: \(error)")
            }
        }

        calls.background {
            do {
                (_, openCageDataJson) = try OpenCageDataLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
print("ocd error: \(error)")
            }
        }

        calls.wait()


        let bestCountryCode = countryCodeFromAll(osmJson, mapzenJson, openCageDataJson)
        var bestCity = cityFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(osmJson, mapzenJson, openCageDataJson, bestCity)
        let bestDescription = descriptionFromAll(osmJson, mapzenJson, openCageDataJson)
        if bestSite == bestCity {
            bestCity = nil
        }

        return Placename(
            site: bestSite,
            city: bestCity,
            state: bestState,
            countryCode: bestCountryCode,
            countryName: bestCountryName,
            fullDescription: bestDescription)
    }

    func testFrom(latitude: Double, longitude: Double) throws -> [String:Any] {
        var response = [String:Any]()
        var osmPlacename: Placename
        var osmJson = JSON()
        var mapzenPlacename: Placename
        var mapzenJson = JSON()
        var openCageDataPlacename: Placename
        var openCageDataJson = JSON()

        do {
            (osmPlacename, osmJson) = try OSMLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["osm"] = [
                "site": osmPlacename.site ?? "",
                "city": osmPlacename.city ?? "",
                "state": osmPlacename.state ?? "",
                "countryCode": osmPlacename.countryCode ?? "",
                "countryName": osmPlacename.countryName ?? "",
                "description": osmPlacename.description,
                "fullDescription": osmPlacename.fullDescription
            ]

            response["osm_address"] = osmJson["address"]
        } catch {
print("osm test error: \(error)")
        }


        do {
            (mapzenPlacename, mapzenJson) = try MapzenLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["mapzen"] = [
                "city": mapzenPlacename.city ?? "",
                "state": mapzenPlacename.state ?? "",
                "countryCode": mapzenPlacename.countryCode ?? "",
                "countryName": mapzenPlacename.countryName ?? "",
                "description": mapzenPlacename.description,
                "fullDescription": mapzenPlacename.fullDescription
            ]

            let properties = mapzenJson["features"][0]["properties"] 
            if properties.exists() {
                response["mapzen_properties"] = properties
            } else {
                print("Mapzen properties missing: \(latitude),\(longitude)")
            }
        } catch {
print("mapzen test error: \(error)")
        }

        do {
            (openCageDataPlacename, openCageDataJson) = try OpenCageDataLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["ocd"] = [
                "city": openCageDataPlacename.city ?? "",
                "state": openCageDataPlacename.state ?? "",
                "countryCode": openCageDataPlacename.countryCode ?? "",
                "countryName": openCageDataPlacename.countryName ?? "",
                "description": openCageDataPlacename.description,
                "fullDescription": openCageDataPlacename.fullDescription
            ]
            
            let components = openCageDataJson["results"][0]["components"]
            if components.exists() {
                response["ocd_components"] = components
                response["ocd_geometry"] = openCageDataJson["results"][0]["geometry"]
            } else {
                print("OpenCageData cache missing components for \(latitude),\(longitude): \(openCageDataJson.rawString()!)")
            }
        } catch {
print("ocd test error: \(error)")
        }

        let bestCountryCode = countryCodeFromAll(osmJson, mapzenJson, openCageDataJson)
        var bestCity = cityFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(osmJson, mapzenJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(osmJson, mapzenJson, openCageDataJson, bestCity)

        if bestSite == bestCity {
            bestCity = nil
        }
        response["best"] = [
            "site": bestSite,
            "city": bestCity,
            "state": bestState,
            "countryCode": bestCountryCode,
            "countryName": bestCountryName,
            "description": [bestSite, bestCity, bestState, bestCountryName].flatMap( { $0 }).joined(separator: ", ")
        ]

        return response
    }

    // Utilize all providers, trying to come up with the best name possible
    func siteFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON, _ city: String?) -> String? {
        // OpenStreetMap is a good source for 'site'; OpenCageData *might* be, too
        // The site name is the first of these components, zero to many may exist
        let osmAddress = osmJson["address"]
        let openCageDataComponents = openCageDataJson["results"][0]["components"]
        var names = [
            openCageDataComponents["attraction"].string,
            osmAddress["attraction"].string,
            osmAddress["archaeological_site"].string,
            osmAddress["castle"].string,
            osmAddress["garden"].string,
            osmAddress["library"].string,
            osmAddress["monument"].string,
            osmAddress["museum"].string,
            osmAddress["place_of_worship"].string,
            osmAddress["stadium"].string,
            osmAddress["viewpoint"].string,
            osmAddress["zoo"].string,

            osmAddress["memorial"].string,

            osmAddress["nature_reserve"].string,
        ]

        // Not all paths are worth including - don't include any in a city
        if city != nil && osmAddress["county"].stringValue == city! {
            names.append(osmAddress["cycleway"].string)
            names.append(openCageDataComponents["cycleway"].string)
            names.append(osmAddress["path"].string)
            names.append(openCageDataComponents["path"].string)
            names.append(openCageDataComponents["footway"].string)
        }

        return names.flatMap({ $0 }).first
    }

    func cityFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {
        let osmAddress = osmJson["address"]
        let mapzenProperties = mapzenJson["features"][0]["properties"]
        let openCageDataComponents = openCageDataJson["results"][0]["components"]

        var mapzenLocality: String? = mapzenProperties["locality"].string
        var osmNeighborhood = osmAddress["neighbourhood"].string
        if let cc = countryCode {
            switch cc {
                case "mx":
                    mapzenLocality = nil
                    osmNeighborhood = nil
                default:
                    break
            }
        }


        let names = [
            mapzenLocality,

            osmAddress["city"].string,
            osmAddress["city_district"].string,
            osmAddress["town"].string,
            osmNeighborhood,
            osmAddress["suburb"].string,
            osmAddress["village"].string,
            osmAddress["county"].string,

            mapzenProperties["localadmin"].string,
            openCageDataComponents["city"].string
        ]
        return names.flatMap({ $0 }).first
    }

    func stateFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

        var names = [
            openCageDataJson["results"][0]["components"]["state_code"].string,
            mapzenJson["features"][0]["properties"]["region_a"].string
        ]

        switch countryCode ?? "" {
            case "gb":
                names = [
                    openCageDataJson["results"][0]["components"]["state_code"].string,
                    openCageDataJson["results"][0]["components"]["state"].string,
                    mapzenJson["features"][0]["properties"]["region_a"].string
                ]

            case "be", "mx":
                return nil

            default:
                break
        }

        return names.flatMap({ $0 }).first
    }

    func countryNameFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

        switch countryCode ?? "" {
            case "us":
                return nil
            case "":
                return mapzenJson["features"][0]["properties"]["label"].string
            default:
                break
        }

        let names = [
            openCageDataJson["results"][0]["components"]["country"].string,
            mapzenJson["features"][0]["properties"]["country"].string
        ]
        return names.flatMap({ $0 }).first
    }

    func countryCodeFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON) -> String? {
        let names = [
            openCageDataJson["results"][0]["components"]["country_code"].string,
            mapzenJson["features"][0]["properties"]["country_a"].string
        ]
        return names.flatMap({ $0 }).first
    }

    func descriptionFromAll(_ osmJson: JSON, _ mapzenJson: JSON, _ openCageDataJson: JSON) -> String {
        let names = [
            openCageDataJson["results"][0]["formatted"].string,
            osmJson["display_name"].string,
            mapzenJson["features"][0]["properties"]["label"].string,
            ""
        ]
        return names.flatMap({ $0 }).first ?? ""
    }
}
