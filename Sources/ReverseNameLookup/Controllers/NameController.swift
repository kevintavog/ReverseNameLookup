import Foundation

import SwiftyJSON
import Vapor

struct NameQueryParams: Codable {
    let lat: Double
    let lon: Double
    let country: Bool?
    let distance: Double?
}


final class NameController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        v1.get("name", use: name)
        v1.get("test", use: test)
        v1.get("cached-name", use: cachedName)
    }

    func name(_ req: Request) throws -> EventLoopFuture<Placename> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = qp.distance ?? 500.0

        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: qp.country ?? false)
            .from(latitude: qp.lat, longitude: qp.lon, distance: Int(distance), cacheOnly: false)
            .map { placename in
                return placename
            }
    }

    func cachedName(_ req: Request) throws -> EventLoopFuture<Placename> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = qp.distance ?? 500.0

        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: qp.country ?? false)
            .from(latitude: qp.lat, longitude: qp.lon, distance: Int(distance), cacheOnly: true)
            .map { placename in
                return placename
            }
    }

    func test(_ req: Request) throws -> EventLoopFuture<String> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = qp.distance ?? 500.0

        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: qp.country ?? false)
            .testFrom(latitude: qp.lat, longitude: qp.lon, distance: Int(distance), cacheOnly: true)
            .map { placename in
                do {
                    return try String(data: JSON(placename).rawData(), encoding: .utf8)!
                } catch {
                    return "Error \(error)"
                }
            }
    }
}
