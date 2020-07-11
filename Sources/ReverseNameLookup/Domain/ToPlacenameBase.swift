import NIO
import Logging

import SwiftyJSON

struct PlacenameAndJson {
    let placename: Placename
    let json: JSON

    init(_ placename: Placename, _ json: JSON) {
        self.placename = placename
        self.json = json
    }
}

class ToPlacenameBase {
    static let logger = Logger(label: "ToPlacenameBase")


    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func from(latitude: Double, longitude: Double, distance: Int, cacheOnly: Bool = false) -> EventLoopFuture<PlacenameAndJson> {
        return fromCache(latitude, longitude, distance)
            .flatMapError { err in
                if !cacheOnly, case NameResolverError.NoMatches = err {
                    return self.fromSource(latitude, longitude, distance)
                        .flatMap { json in
                            self.saveToCache(latitude, longitude, json)
                            return self.eventLoop.makeSucceededFuture(json)
                        }
                } else {
                    ToPlacenameBase.logger.error("cache error: \(err)")
                    return self.eventLoop.makeFailedFuture(err)
                }
            }
            .flatMap { json in
                return self.convert(latitude, longitude, json)
            }
    }

    func convert(_ latitude: Double, _ longitude: Double, _ json: JSON) -> EventLoopFuture<PlacenameAndJson> {
        do {
            return try eventLoop.makeSucceededFuture(
                PlacenameAndJson(toPlacename(latitude, longitude, json), json))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    func placenameIdentifier() -> String {
        return "'placenameIdentifier' is not implemented in the derived class"
    }

    func fromCache(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return eventLoop.makeFailedFuture(
            LocationToNameInfo.Error.NotImplemented("'fromCache' is not implemented in the derived class"))
    }

    func fromSource(_ latitude: Double, _ longitude: Double, _ distance: Int) -> EventLoopFuture<JSON> {
        return eventLoop.makeFailedFuture(
            LocationToNameInfo.Error.NotImplemented("'fromSource' is not implemented in the derived class"))
    }

    func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) {
        ToPlacenameBase.logger.error("'saveToCache' is not implemented in the derived class")
    }

    func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        throw LocationToNameInfo.Error.NotImplemented("'toPlacename' is not implemented in the derived class")
    }
}
