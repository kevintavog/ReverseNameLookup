import Foundation
import Logging
import NIO

import SwiftyJSON

class OpenCageDataLocationToPlacename : ToPlacenameBase{
    static let indexName = "opencagedata_placenames_cache"

    init(eventLoop: EventLoop) {
        super.init(eventLoop: eventLoop, indexName: OpenCageDataLocationToPlacename.indexName)
    }

    override func placenameIdentifier() -> String {
        return "OpenCageData"
    }

    override func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return OpenCageDataNameResolver(eventLoop: eventLoop).resolve(latitude, longitude, maxDistanceInMeters: distance)
    }

    override func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        let components = json["results"][0]["components"]
        if !components.exists() {
            throw LocationToNameInfo.Error.NoAddress("\(json)")
        }

        if json["results"][1].exists() {
            OpenCageDataLocationToPlacename.logger.warning("OpenCageData has multiple results: \(json["results"])")
        }

        let site = siteName(components)
        return Placename(
            sites: site == nil ? nil : [site!],
            site: site,
            city: components["city"].string,
            state: components["state_code"].string,
            countryCode: components["country_code"].string,
            countryName: components["country"].string,
            fullDescription: json["results"][0]["formatted"].stringValue)
    }

    fileprivate func siteName(_ components: JSON) -> String? {
        return [
            components["attraction"].string,
            components["archaeological_site"].string,
            components["body_of_water"].string,
            components["castle"].string,
            components["garden"].string,
            components["library"].string,
            components["museum"].string,
            components["place_of_worship"].string,
            components["ruins"].string,
            components["stadium"].string,
            components["zoo"].string,
        ].compactMap({ $0 }).first
    }
}