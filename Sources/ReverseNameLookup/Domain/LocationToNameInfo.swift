import Foundation
import Logging
import NIO

import SwiftyJSON

class LocationToNameInfo {
    static let logger = Logger(label: "LocationToNameInfo")

    enum Error : Swift.Error {
        case NoMatches
        case NoDataInResponse
        case NoLatLon(String)
        case NoAddress(String)
        case NotImplemented(String)
    }

    let eventLoop: EventLoop
    let alwaysInludeCountryName: Bool
    let placenameCache: PlacenameCache

    init(eventLoop: EventLoop, includeCountryName: Bool) {
        self.eventLoop = eventLoop
        self.alwaysInludeCountryName = includeCountryName
        self.placenameCache = PlacenameCache(eventLoop)
    }

    func fromResult(_ result: Result<PlacenameAndJson, Swift.Error>) -> PlacenameAndJson {
        switch result {
            case .failure(let error):
                LocationToNameInfo.logger.error("Error getting result: \(error)")
                return PlacenameAndJson(
                    Placename(sites: nil, site: nil, city: nil, state: nil, countryCode: nil, countryName: nil, fullDescription: ""),
                    JSON()
                )
            case .success(let placenameAndJson):
                return placenameAndJson
        }
    }

    func _from(_ latitude: Double, _ longitude: Double, _ distance: Int, _ cacheOnly: Bool = false, 
                _ callback: @escaping (_ azurePJ: PlacenameAndJson, _ foursquarePJ: PlacenameAndJson,
                _ openCageDataPJ: PlacenameAndJson, _ overpassPJ: PlacenameAndJson) -> Void) {

        let futures = [
            AzureLocationToPlacename(eventLoop: eventLoop)
                .from(latitude: latitude, longitude: longitude, distance: distance, cacheOnly: cacheOnly),
            FoursquareLocationToPlacename(eventLoop: eventLoop)
                .from(latitude: latitude, longitude: longitude, distance: distance, cacheOnly: cacheOnly),
            OpenCageDataLocationToPlacename(eventLoop: eventLoop)
                .from(latitude: latitude, longitude: longitude, distance: distance, cacheOnly: cacheOnly),
            OverpassLocationToPlacename(eventLoop: eventLoop)
                .from(latitude: latitude, longitude: longitude, distance: distance, cacheOnly: cacheOnly)
        ]

        EventLoopFuture.whenAllComplete(futures, on: eventLoop)
            .whenSuccess { results in
                let azurePJ = self.fromResult(results[0])
                let foursquarePJ = self.fromResult(results[1])
                let openCageDataPJ = self.fromResult(results[2])
                let overpassPJ = self.fromResult(results[3])

                callback(azurePJ, foursquarePJ, openCageDataPJ, overpassPJ)
            }
    }


    func from(latitude: Double, longitude: Double, distance: Int, cacheOnly: Bool) -> EventLoopFuture<Placename> {
        let promise = eventLoop.makePromise(of: Placename.self)

        _from(latitude, longitude, distance, cacheOnly) { azurePJ, foursquarePJ, openCageDataPJ, overpassPJ in
            promise.succeed(self.toPlacename(azurePJ, foursquarePJ, openCageDataPJ, overpassPJ))
        }

        return promise.futureResult
    }

    func bulk(items: [BulkItemRequest], distance: Int, cacheOnly: Bool) -> EventLoopFuture<[BulkItemResponse]> {
        let promise = eventLoop.makePromise(of: [BulkItemResponse].self)

        placenameCache.lookup(items, 3)
            .whenComplete { result in
                // If even a single item fails, retrieve from the resolvers (which checks the
                // provider specific cache first)
                var failed = false
                switch result {
                    case .failure(let error):
print("placename cache error: \(error)")
                        failed = true
                        break
                    case .success(let placenames):
                        failed = placenames.firstIndex(where: { $0 == nil }) != nil
                        if !failed {
                            // Convert to [BulkItemRespose] & return it
                            var response = [BulkItemResponse]()
                            for p in placenames {
                                response.append(BulkItemResponse(p, nil))
                            }
                            promise.succeed(response)
                        }
                        break
                }

                if failed {
                    self.bulkFromResolvers(items, distance, cacheOnly)
                        .whenComplete { bulkResult in
                            switch bulkResult {
                                case .failure(let error):
                                    promise.fail(error)
                                    break
                                case .success(let bulkResponses):
                                    promise.succeed(bulkResponses)
                                    break
                            }
                        }
                }
            }

        return promise.futureResult
    }

    func bulkFromResolvers(_ items: [BulkItemRequest], _ distance: Int, _ cacheOnly: Bool) 
                                -> EventLoopFuture<[BulkItemResponse]> {
        let azure = AzureLocationToPlacename(eventLoop: eventLoop)
        let foursquare = FoursquareLocationToPlacename(eventLoop: eventLoop)
        let openCageData = OpenCageDataLocationToPlacename(eventLoop: eventLoop)
        let overpass = OverpassLocationToPlacename(eventLoop: eventLoop)

        return azure.bulk(items, [azure, foursquare, openCageData, overpass], distance)
            .map { nameAndJson in
                var responses: [BulkItemResponse] = []
                let groupSize = 4
                let groups = stride(from: 0, to: nameAndJson.count, by: groupSize)
                    .map { Array(nameAndJson[$0..<min($0 + groupSize, nameAndJson.count)]) }
                for g in groups {
                    responses.append(
                        BulkItemResponse(
                            self.toPlacename(g[0], g[1], g[2], g[3]),
                            nil)
                        )
                }
                return responses
        }
    }

    func toPlacename(_ azurePJ: PlacenameAndJson, _ foursquarePJ: PlacenameAndJson, 
                        _ openCageDataPJ: PlacenameAndJson, _ overpassPJ: PlacenameAndJson) -> Placename {
        let bestCountryCode = self.countryCodeFromAll(overpassPJ, azurePJ, openCageDataPJ)
        var bestCity = self.cityFromAll(overpassPJ, azurePJ, foursquarePJ, openCageDataPJ, bestCountryCode)
        let bestState = self.stateFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCountryCode)
        let bestCountryName = self.countryNameFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCountryCode)
        let (bestSite, allSites) = self.siteFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCity)
        let bestFullDescription = self.descriptionFromAll(overpassPJ, azurePJ, openCageDataPJ)
        if bestSite == bestCity {
            bestCity = nil
        }

        let (latitude, longitude) = self.location(overpassPJ, openCageDataPJ, azurePJ)

        var placename = Placename(
            sites: allSites,
            site: bestSite,
            city: bestCity,
            state: bestState,
            countryCode: bestCountryCode,
            countryName: bestCountryName,
            fullDescription: bestFullDescription)
        placename.latitude = latitude
        placename.longitude = longitude

        self.placenameCache.save(placename)

        return placename
    }

    func testFrom(latitude: Double, longitude: Double, distance: Int, cacheOnly: Bool) -> EventLoopFuture<[String:Any]> {
        let promise = eventLoop.makePromise(of: [String:Any].self)

        _from(latitude, longitude, distance, cacheOnly) { azurePJ, foursquarePJ, openCageDataPJ, overpassPJ in
            let bestCountryCode = self.countryCodeFromAll(overpassPJ, azurePJ, openCageDataPJ)
            var bestCity = self.cityFromAll(overpassPJ, azurePJ, foursquarePJ, openCageDataPJ, bestCountryCode)
            let bestState = self.stateFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCountryCode)
            let bestCountryName = self.countryNameFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCountryCode)
            let (bestSite, allSites) = self.siteFromAll(overpassPJ, azurePJ, openCageDataPJ, bestCity)
            let bestFullDescription = self.descriptionFromAll(overpassPJ, azurePJ, openCageDataPJ)
            if bestSite == bestCity {
                bestCity = nil
            }


            var response = [String:Any]()
            response["azure"] = self.toDictionary(azurePJ.placename)
            response["foursquare"] = self.toDictionary(foursquarePJ.placename)
            response["ocd"] = self.toDictionary(openCageDataPJ.placename)
            if openCageDataPJ.json["results"].exists() {
                response["ocd_results"] = openCageDataPJ.json["results"]
            }
            response["overpass"] = self.toDictionary(overpassPJ.placename)
            response["overpass_elements"] = overpassPJ.json["elements"]

        let siteDescription = allSites != nil ? allSites!.compactMap { $0 }.joined(separator: ", ") : nil
            response["best"] = [
                "sites": allSites ?? [String](),
                "site": bestSite ?? "",
                "city": bestCity ?? "",
                "state": bestState ?? "",
                "countryCode": bestCountryCode ?? "",
                "countryName": bestCountryName ?? "",
                "fullDescription": bestFullDescription,
                "description": [siteDescription, bestCity, bestState, bestCountryName].compactMap( { $0 }).joined(separator: ", ")
            ]

            promise.succeed(response)
        }

        return promise.futureResult
    }

    func toDictionary(_ placename: Placename) -> [String: Any] {
        return [
            "sites": placename.sites ?? [String](),
            "site": placename.site ?? "",
            "city": placename.city ?? "",
            "state": placename.state ?? "",
            "countryCode": placename.countryCode ?? "",
            "countryName": placename.countryName ?? "",
            "description": placename.description,
            "fullDescription": placename.fullDescription
        ]
    }

    func location(_ overpass: PlacenameAndJson, _ openCageData: PlacenameAndJson,
                    _ azure: PlacenameAndJson) -> (Double?,Double?) {
        let locations = [
            overpass.json["location"],
            openCageData.json["location"],
            azure.json["location"],
        ]

        for l in locations {
            if let lat = l["lat"].double {
                return (lat, l["lon"].double)
            }
        }

        return (nil, nil)
    }


    // Utilize all providers, trying to come up with the best name possible
    func siteFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                        _ openCageData: PlacenameAndJson, _ city: String?) -> (String?,[String]?) {

        // Always prefer results from Overpass, as it's the site the location is in, rather than near
        if overpass.placename.sites != nil || overpass.placename.site != nil {
            return (overpass.placename.site, overpass.placename.sites)
        }

        let openCageDataComponents = openCageData.json["results"][0]["components"]
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

        if overpass.placename.city == nil {
            var addSite = true

            // Don't inclue the site if we're in a city
            if let county = openCageDataComponents["county"].string, let city = openCageDataComponents["city"].string {
                addSite = county != city
            }
            if addSite {
                names.append(openCageDataComponents["cycleway"].string)
                names.append(openCageDataComponents["path"].string)
                names.append(openCageDataComponents["footway"].string)
            }
        }

        let site = names.compactMap({ $0 }).first
        var sites: [String]? = nil
        if site != nil {
            sites = [site!]
        }
        return (site, sites)
    }

    func cityFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                        _ foursquare: PlacenameAndJson, _ openCageData: PlacenameAndJson,
                        _ countryCode: String?) -> String? {

        // Always prefer results from Overpass, as it's the city the location is in, rather than near
        if overpass.placename.city != nil {
            return overpass.placename.city
        }

        let azureAddress = azure.json["addresses"][0]["address"]
        let openCageDataComponents = openCageData.json["results"][0]["components"]

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
            if azure.json["addresses"][0]["entityType"].exists() {
                azureMunicipality = nil
            }
        }

        let names = [
            azureMunicipality,
            FoursquareLocationToPlacename.getCity(foursquare.json),
            openCageDataComponents["city"].string
        ]

        return names.compactMap({ $0 }).first
    }

    func stateFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                        _ openCageData: PlacenameAndJson, _ countryCode: String?) -> String? {
        var names = [
            openCageData.json["results"][0]["components"]["state_code"].string,
        ]

        switch countryCode ?? "" {
            case "gb":
                names = [
                    openCageData.json["results"][0]["components"]["state_code"].string,
                    openCageData.json["results"][0]["components"]["state"].string,
                    azure.json["addresses"][0]["address"]["countrySubdivision"].string
                ]

            case "be", "fr", "mx":
                return nil

            case "ca", "us":
                names.insert(azure.json["addresses"][0]["address"]["countrySubdivision"].string, at: 0)
                break

            default:
                break
        }

        return names.compactMap({ $0 }).first
    }

    func countryNameFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                            _ openCageData: PlacenameAndJson, _ countryCode: String?) -> String? {
        switch countryCode ?? "" {
            case "us":
                if !alwaysInludeCountryName  {
                    return nil
                }
                return "USA"    // Override some old data "United States of America"
            case "":
                return azure.json["addresses"][0]["address"]["country"].string
            default:
                break
        }

        let names = [
            openCageData.json["results"][0]["components"]["country"].string,
            azure.json["addresses"][0]["address"]["country"].string,
        ]
        return names.compactMap({ $0 }).first
    }

    func countryCodeFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                            _ openCageData: PlacenameAndJson) -> String? {
        let names = [
            openCageData.json["results"][0]["components"]["country_code"].string,
            azure.json["addresses"][0]["address"]["countryCode"].string,
        ]
        return names.compactMap({ $0 }).first
    }

    func descriptionFromAll(_ overpass: PlacenameAndJson, _ azure: PlacenameAndJson,
                            _ openCageData: PlacenameAndJson) -> String {
        let names = [
            openCageData.json["results"][0]["formatted"].string,
            overpass.placename.fullDescription,
            ""
        ]
        return names.compactMap({ $0 }).first ?? ""
    }
}
