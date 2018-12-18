import Foundation
import Queuer
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
        var azureJson = JSON()
        var foursquareJson = JSON()
        // var mapzenJson = JSON()
        var osmJson = JSON()
        var openCageDataJson = JSON()


        let queue = Queuer(name: "calls")
        queue.addOperation {
            do {
                (_, azureJson) = try AzureLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("azure error: \(error)")
            }
        }

        queue.addOperation {
            do {
                (_, foursquareJson) = try FoursquareLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("foursquare error: \(error)")
            }
        }

//         queue.addOperation {
//             do {
//                 (_, mapzenJson) = try MapzenLocationToPlacename().from(latitude: latitude, longitude: longitude)
//             } catch {
// Logger.log("mapzen error: \(error)")
//             }
//         }

        queue.addOperation {
            do {
                (_, osmJson) = try OSMLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("osm error: \(error)")
            }
        }

        queue.addOperation {
            do {
                (_, openCageDataJson) = try OpenCageDataLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("ocd error: \(error)")
            }
        }

        queue.queue.waitUntilAllOperationsAreFinished()


        let bestCountryCode = countryCodeFromAll(azureJson, osmJson, openCageDataJson)
        var bestCity = cityFromAll(azureJson, foursquareJson, osmJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(azureJson, osmJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(azureJson, osmJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(azureJson, osmJson, openCageDataJson, bestCity)
        let bestDescription = descriptionFromAll(azureJson, osmJson, openCageDataJson)
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
        var azurePlacename: Placename
        var azureJson = JSON()
        var foursquarePlacename: Placename
        var foursquareJson = JSON()
        // var mapzenPlacename: Placename
        // var mapzenJson = JSON()
        var openCageDataPlacename: Placename
        var openCageDataJson = JSON()
        var osmPlacename: Placename
        var osmJson = JSON()


        do {
            (azurePlacename, azureJson) = try AzureLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["azure"] = [
                "city": azurePlacename.city ?? "",
                "state": azurePlacename.state ?? "",
                "countryCode": azurePlacename.countryCode ?? "",
                "countryName": azurePlacename.countryName ?? "",
                "description": azurePlacename.description,
                "fullDescription": azurePlacename.fullDescription
            ]

            response["azure_results"] = azureJson["addresses"]
        } catch {
Logger.log("azure test error: \(error)")
        }


        do {
            (foursquarePlacename, foursquareJson) = try FoursquareLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["foursquare"] = [
                "site": foursquarePlacename.site ?? "",
                "city": foursquarePlacename.city ?? "",
                "state": foursquarePlacename.state ?? "",
                "countryCode": foursquarePlacename.countryCode ?? "",
                "countryName": foursquarePlacename.countryName ?? "",
                "description": foursquarePlacename.description,
                "fullDescription": foursquarePlacename.fullDescription
            ]

            response["foursquare_compact"] = foursquareJson["compact_venues"]
        } catch {
Logger.log("foursquare test error: \(error)")
        }


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
Logger.log("osm test error: \(error)")
        }


//         do {
//             (mapzenPlacename, mapzenJson) = try MapzenLocationToPlacename().from(latitude: latitude, longitude: longitude)
//             response["mapzen"] = [
//                 "city": mapzenPlacename.city ?? "",
//                 "state": mapzenPlacename.state ?? "",
//                 "countryCode": mapzenPlacename.countryCode ?? "",
//                 "countryName": mapzenPlacename.countryName ?? "",
//                 "description": mapzenPlacename.description,
//                 "fullDescription": mapzenPlacename.fullDescription
//             ]

//             let properties = mapzenJson["features"][0]["properties"] 
//             if properties.exists() {
//                 response["mapzen_properties"] = properties
//             } else {
//                 Logger.log("Mapzen properties missing: \(latitude),\(longitude)")
//             }
//         } catch {
// Logger.log("mapzen test error: \(error)")
//         }

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
                Logger.log("OpenCageData cache missing components for \(latitude),\(longitude): \(openCageDataJson.rawString()!)")
            }
        } catch {
Logger.log("ocd test error: \(error)")
        }

        let bestCountryCode = countryCodeFromAll(azureJson, osmJson, openCageDataJson)
        var bestCity = cityFromAll(azureJson, foursquareJson, osmJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(azureJson, osmJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(azureJson, osmJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(azureJson, osmJson, openCageDataJson, bestCity)

        if bestSite == bestCity {
            bestCity = nil
        }
        response["best"] = [
            "site": bestSite ?? "",
            "city": bestCity ?? "",
            "state": bestState ?? "",
            "countryCode": bestCountryCode ?? "",
            "countryName": bestCountryName ?? "",
            "description": [bestSite, bestCity, bestState, bestCountryName].compactMap( { $0 }).joined(separator: ", ")
        ]

        return response
    }

    // Utilize all providers, trying to come up with the best name possible
    func siteFromAll(_ azureJson: JSON, _ osmJson: JSON, _ openCageDataJson: JSON, _ city: String?) -> String? {
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

        return names.compactMap({ $0 }).first
    }

    func cityFromAll(_ azureJson: JSON, _ foursquareJson: JSON, _ osmJson: JSON,
                     _ openCageDataJson: JSON, _ countryCode: String?) -> String? {
        let azureAddress = azureJson["addresses"][0]["address"]
        let osmAddress = osmJson["address"]
        let openCageDataComponents = openCageDataJson["results"][0]["components"]

        var azureMunicipality: String? = azureAddress["municipality"].string
        var osmNeighborhood = osmAddress["neighbourhood"].string
        if let cc = countryCode {
            switch cc {
                case "mx":
                    osmNeighborhood = nil
                    azureMunicipality = nil
                default:
                    break
            }
        }

        // Azure returns city names that contain two cities - get rid of those
        if let city = azureMunicipality {
            if city.contains(",") {
                azureMunicipality = nil
            }
        }

        // Azure includes neighbord hoods names for the city, but denotes the record with an entityType
        if azureMunicipality != nil {
            if azureJson["addresses"][0]["entityType"].exists() {
                azureMunicipality = nil
            }
        }

        let names = [
            azureMunicipality,

            FoursquareLocationToPlacename.getCity(foursquareJson),

            osmAddress["city"].string,
            osmAddress["city_district"].string,
            osmAddress["town"].string,
            osmNeighborhood,
            osmAddress["suburb"].string,
            osmAddress["village"].string,
            osmAddress["county"].string,

            openCageDataComponents["city"].string
        ]

        return names.compactMap({ $0 }).first
    }

    func stateFromAll(_ azureJson: JSON, _ osmJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

        var names = [
            openCageDataJson["results"][0]["components"]["state_code"].string,
        ]

        switch countryCode ?? "" {
            case "gb":
                names = [
                    openCageDataJson["results"][0]["components"]["state_code"].string,
                    openCageDataJson["results"][0]["components"]["state"].string,
                    azureJson["addresses"][0]["address"]["countrySubdivision"].string
                ]

            case "be", "mx":
                return nil

            case "ca", "us":
                names.insert(azureJson["addresses"][0]["address"]["countrySubdivision"].string, at: 0)
                break

            default:
                break
        }

        return names.compactMap({ $0 }).first
    }

    func countryNameFromAll(_ azureJson: JSON, _ osmJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

        switch countryCode ?? "" {
            case "us":
                return nil
            case "":
                return azureJson["addresses"][0]["address"]["country"].string
            default:
                break
        }

        let names = [
            openCageDataJson["results"][0]["components"]["country"].string,
            azureJson["addresses"][0]["address"]["country"].string,
        ]
        return names.compactMap({ $0 }).first
    }

    func countryCodeFromAll(_ azureJson: JSON, _ osmJson: JSON, _ openCageDataJson: JSON) -> String? {
        let names = [
            openCageDataJson["results"][0]["components"]["country_code"].string,
            azureJson["addresses"][0]["address"]["countryCode"].string,
        ]
        return names.compactMap({ $0 }).first
    }

    func descriptionFromAll(_ azureJson: JSON, _ osmJson: JSON, _ openCageDataJson: JSON) -> String {
        let names = [
            openCageDataJson["results"][0]["formatted"].string,
            osmJson["display_name"].string,
            ""
        ]
        return names.compactMap({ $0 }).first ?? ""
    }
}
