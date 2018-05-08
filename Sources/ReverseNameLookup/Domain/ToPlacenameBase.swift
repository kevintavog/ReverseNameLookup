import SwiftyJSON


class ToPlacenameBase {
    func from(latitude: Double, longitude: Double) throws -> (Placename, JSON) {
        var response: JSON?

        do {
            response = try fromCache(latitude, longitude)
        } catch NameResolverError.NoMatches {
            // The cache doesn't have this entry, no value in logging that info
        }  catch {
print("cache exception: \(error)")
        }

        // Not in the cache, get it from the source
        if response == nil {
            do {
                try print("Getting location from source: \(latitude),\(longitude) - \(placenameIdentifier())")
                response = try fromSource(latitude, longitude)
            } catch {
print("fromSource exception: \(error)")
            }

            if response != nil {
                // This can be done asynchronously - it'll shave off a bit of request time/duration
                do {
                    try saveToCache(latitude, longitude, response!)
                } catch {
                    print("Caching of \(latitude), \(longitude) failed: \(error)")
                }
            }
        }

        guard let json = response else {
            throw LocationToNameInfo.Error.NoDataInResponse
        }

        return try (toPlacename(latitude, longitude, json), json)
    }

    func placenameIdentifier() throws -> String {
        throw LocationToNameInfo.Error.NotImplemented("'placenameIdentifier' is not implemented in the derived class")
    }

    func fromCache(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        throw LocationToNameInfo.Error.NotImplemented("'fromCache' is not implemented in the derived class")
    }

    func fromSource(_ latitude: Double, _ longitude: Double) throws -> JSON? {
        throw LocationToNameInfo.Error.NotImplemented("'fromSource' is not implemented in the derived class")
    }

    func saveToCache(_ latitude: Double, _ longitude: Double, _ json: JSON) throws {
        throw LocationToNameInfo.Error.NotImplemented("'saveToCache' is not implemented in the derived class")
    }

    func toPlacename(_ latitude: Double, _ longitude: Double, _ json: JSON) throws -> Placename {
        throw LocationToNameInfo.Error.NotImplemented("'toPlacename' is not implemented in the derived class")
    }
}
