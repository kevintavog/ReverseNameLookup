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
        var openCageDataJson = JSON()
        var overpassPlacename: Placename = Placename(site: nil, city: nil, state: nil, countryCode: nil, countryName: nil, fullDescription: "")


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

        queue.addOperation {
            do {
                (_, openCageDataJson) = try OpenCageDataLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("opencagedata error: \(error)")
            }
        }

        queue.addOperation {
            do {
                (overpassPlacename, _) = try OverpassLocationToPlacename().from(latitude: latitude, longitude: longitude)
            } catch {
Logger.log("overpass error: \(error)")
            }
        }

        queue.queue.waitUntilAllOperationsAreFinished()

        let bestCountryCode = countryCodeFromAll(overpassPlacename, azureJson, openCageDataJson)
        var bestCity = cityFromAll(overpassPlacename, azureJson, foursquareJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(overpassPlacename, azureJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(overpassPlacename, azureJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(overpassPlacename, azureJson, openCageDataJson, bestCity)
        let bestDescription = descriptionFromAll(overpassPlacename, azureJson, openCageDataJson)
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
        var openCageDataPlacename: Placename
        var openCageDataJson = JSON()
        var overpassPlacename: Placename = Placename(site: nil, city: nil, state: nil, countryCode: nil, countryName: nil, fullDescription: "")
        var overpassJson = JSON()


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
            (openCageDataPlacename, openCageDataJson) = try OpenCageDataLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["ocd"] = [
                "city": openCageDataPlacename.city ?? "",
                "state": openCageDataPlacename.state ?? "",
                "countryCode": openCageDataPlacename.countryCode ?? "",
                "countryName": openCageDataPlacename.countryName ?? "",
                "description": openCageDataPlacename.description,
                "fullDescription": openCageDataPlacename.fullDescription
            ]

            if openCageDataJson["results"].exists() {
                response["ocd_results"] = openCageDataJson["results"]
            }
        } catch {
Logger.log("ocd test error: \(error)")
        }

        do {
            (overpassPlacename, overpassJson) = try OverpassLocationToPlacename().from(latitude: latitude, longitude: longitude)
            response["overpass"] = [
                "site": overpassPlacename.site ?? "",
                "city": overpassPlacename.city ?? "",
                "state": overpassPlacename.state ?? "",
                "countryCode": overpassPlacename.countryCode ?? "",
                "countryName": overpassPlacename.countryName ?? "",
                "description": overpassPlacename.description,
                "fullDescription": overpassPlacename.fullDescription
            ]

            response["overpass_elements"] = overpassJson["elements"]
        } catch {
Logger.log("overpass test error: \(error)")
        }

        let bestCountryCode = countryCodeFromAll(overpassPlacename, azureJson, openCageDataJson)
        var bestCity = cityFromAll(overpassPlacename, azureJson, foursquareJson, openCageDataJson, bestCountryCode)
        let bestState = stateFromAll(overpassPlacename, azureJson, openCageDataJson, bestCountryCode)
        let bestCountryName = countryNameFromAll(overpassPlacename, azureJson, openCageDataJson, bestCountryCode)
        let bestSite = siteFromAll(overpassPlacename, azureJson, openCageDataJson, bestCity)

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
    func siteFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ openCageDataJson: JSON, _ city: String?) -> String? {

        // Always prefer results from Overpass, as it's the site the location is in, rather than near
        if overpassPlacename.site != nil {
            return overpassPlacename.site
        }

        let openCageDataComponents = openCageDataJson["results"][0]["components"]
        var names = [
            openCageDataComponents["attraction"].string,
            openCageDataComponents["archaeological_site"].string,
            openCageDataComponents["artwork"].string,
            openCageDataComponents["body_of_water"].string,
            openCageDataComponents["castle"].string,
            openCageDataComponents["garden"].string,
            openCageDataComponents["memorial"].string,
            openCageDataComponents["museum"].string,
            openCageDataComponents["place_of_worship"].string,
            openCageDataComponents["ruins"].string,
            openCageDataComponents["stadium"].string,
            openCageDataComponents["zoo"].string,
        ]



        // openCageData has a few more _types that *might* be interesting; perhaps these ought to be a secondary site?
        //  "beach", "library", "memorial", "monument", "nature_reserve", "park", 
        //  "university", "viewpoint",

        if overpassPlacename.city == nil {
            names.append(openCageDataComponents["cycleway"].string)
            names.append(openCageDataComponents["path"].string)
            names.append(openCageDataComponents["footway"].string)
        }

        // Not all paths are worth including - don't include any in a city
/*        if city != nil && osmAddress["county"].stringValue == city! {
            names.append(osmAddress["cycleway"].string)
            names.append(openCageDataComponents["cycleway"].string)
            names.append(osmAddress["path"].string)
            names.append(openCageDataComponents["path"].string)
            names.append(openCageDataComponents["footway"].string)
        }
*/
        return names.compactMap({ $0 }).first
    }

    func cityFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ foursquareJson: JSON,
                     _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

        // Always prefer results from Overpass, as it's the city the location is in, rather than near
        if overpassPlacename.city != nil {
            return overpassPlacename.city
        }

        let azureAddress = azureJson["addresses"][0]["address"]
        let openCageDataComponents = openCageDataJson["results"][0]["components"]

        var azureMunicipality: String? = azureAddress["municipality"].string
        if let cc = countryCode {
            switch cc {
                case "mx":
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
            openCageDataComponents["city"].string
        ]

        return names.compactMap({ $0 }).first
    }

    func stateFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

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

    func countryNameFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ openCageDataJson: JSON, _ countryCode: String?) -> String? {

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

    func countryCodeFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ openCageDataJson: JSON) -> String? {
        let names = [
            openCageDataJson["results"][0]["components"]["country_code"].string,
            azureJson["addresses"][0]["address"]["countryCode"].string,
        ]
        return names.compactMap({ $0 }).first
    }

    func descriptionFromAll(_ overpassPlacename: Placename, _ azureJson: JSON, _ openCageDataJson: JSON) -> String {
        let names = [
            openCageDataJson["results"][0]["formatted"].string,
            overpassPlacename.fullDescription,
            ""
        ]
        return names.compactMap({ $0 }).first ?? ""
    }
}
