import Foundation
import SwiftyJSON

import PerfectHTTP


class Handlers {

    enum NameError: Error {
        case bogus
    }


    static func getName(request: HTTPRequest, _ response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        defer { response.completed() }

        do {
            let (lat, latErr) = asDouble(request, "lat")
            if latErr != nil {
                Handlers.error(request, response, message: latErr!)
            }
            let (lon, lonErr) = asDouble(request, "lon")
            if lonErr != nil {
                Handlers.error(request, response, message: lonErr!)
            }
            let includeCountryName = asOptionaBool(request, "country", false)

            let placename = try LocationToNameInfo(includeCountryName: includeCountryName)
                .from(latitude: lat, longitude: lon, distance: 3)

            request.scratchPad["description"] = placename.fullDescription
            let encodedData = try JSONEncoder().encode(placename)
            response.setBody(string: String(data: encodedData, encoding: .utf8)!)
        } catch {
            Handlers.error(request, response, error)
        }
    }

    static func getCachedName(request: HTTPRequest, _ response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        defer { response.completed() }

        do {
            let (lat, latErr) = asDouble(request, "lat")
            if latErr != nil {
                Handlers.error(request, response, message: latErr!)
            }
            let (lon, lonErr) = asDouble(request, "lon")
            if lonErr != nil {
                Handlers.error(request, response, message: lonErr!)
            }
            let includeCountryName = asOptionaBool(request, "country", false)
            var (distance, err) = asDouble(request, "distance")
            if err != nil {
                distance = 500.0
            }

            let placename = try LocationToNameInfo(includeCountryName: includeCountryName)
                .from(latitude: lat, longitude: lon, distance: Int(distance), cacheOnly: true)

            request.scratchPad["description"] = placename.fullDescription
            let encodedData = try JSONEncoder().encode(placename)
            response.setBody(string: String(data: encodedData, encoding: .utf8)!)
        } catch {
            Handlers.error(request, response, error)
        }
    }

    static func testName(request: HTTPRequest, _ response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        defer { response.completed() }

        do {
            let (lat, latErr) = asDouble(request, "lat")
            if latErr != nil {
                Handlers.error(request, response, message: latErr!)
            }
            let (lon, lonErr) = asDouble(request, "lon")
            if lonErr != nil {
                Handlers.error(request, response, message: lonErr!)
            }

            let placename = try LocationToNameInfo(includeCountryName: false).testFrom(latitude: lat, longitude: lon)

            let encodedData = try JSON(placename).rawData()
            response.setBody(string: String(data: encodedData, encoding: .utf8)!)
        } catch {
            Handlers.error(request, response, error)
        }
    }

    static func asDouble(_ request: HTTPRequest, _ name: String) -> (Double, String?) {
        guard let param = request.param(name: name) else {
            return (0, "\(name) must be specified")
        }

        guard let val = Double(param) else {
            return (0, "\(name) must be a number")
        }
        return (val, nil)
    }

    static func asOptionaBool(_ request: HTTPRequest, _ name: String, _ defaultValue: Bool) -> Bool {
        guard let param = request.param(name: name) else {
            return defaultValue
        }

        guard let val = Bool(param) else {
            return defaultValue
        }
        return val
    }

}
