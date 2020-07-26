import Foundation

import SwiftyJSON
import Vapor

struct NameQueryParams: Codable {
    let lat: Double
    let lon: Double
    let country: Bool?
    let distance: Double?
}

struct BulkRequest: Content {
    let items: [BulkItemRequest]
    let cacheOnly: Bool?
    let country: Bool?
    let distance: Double?
}

struct BulkResponse: Content {
    let hadErrors: Bool
    let items: [BulkItemResponse]

    init(_ items: [BulkItemResponse]) {
        self.hadErrors = items.contains { $0.error != nil }
        self.items = items
    }
}

final class NameController: RouteCollection {
    let defaultDistance = 100.0

    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        api.get("name", use: name)
        api.post("bulk", use: bulk)
        api.get("test", use: test)
        api.get("cached-name", use: cachedName)
    }

    func name(_ req: Request) throws -> EventLoopFuture<Placename> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = Int(qp.distance ?? defaultDistance)

        let items = [BulkItemRequest(lat: qp.lat, lon: qp.lon)]
        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: qp.country ?? false)
            .bulk(items: items, distance: distance, cacheOnly: false)
            .map { responses in
                return responses[0].placename!
            }
    }

    func bulk(_ req: Request) throws -> EventLoopFuture<BulkResponse> {
        let bulkRequest = try req.content.decode(BulkRequest.self)
        let cacheOnly = bulkRequest.cacheOnly ?? false
        let country = bulkRequest.country ?? false
        let distance = Int(bulkRequest.distance ?? defaultDistance)

        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: country)
            .bulk(items: bulkRequest.items, distance: distance, cacheOnly: cacheOnly)
            .map { responses in
                return BulkResponse(responses)
            }
    }

    func cachedName(_ req: Request) throws -> EventLoopFuture<Placename> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = qp.distance ?? defaultDistance

        return LocationToNameInfo(eventLoop: req.eventLoop, includeCountryName: qp.country ?? false)
            .from(latitude: qp.lat, longitude: qp.lon, distance: Int(distance), cacheOnly: true)
    }

    func test(_ req: Request) throws -> EventLoopFuture<String> {
        let qp = try req.query.decode(NameQueryParams.self)
        let distance = qp.distance ?? defaultDistance

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
