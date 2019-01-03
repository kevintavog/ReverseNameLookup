import Foundation

import PerfectHTTP
import SwiftyJSON


class Handlers {

    enum NameError: Error {
        case bogus
    }


    static func getName(request: HTTPRequest, _ response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
        defer { response.completed() }

        do {
            guard let latParam = request.param(name: "lat") else {
                Handlers.error(request, response, message: "lat must be specified")
                return                
            }
            guard let lonParam = request.param(name: "lon") else {
                Handlers.error(request, response, message: "lon must be specified")
                return
            }

            guard let lat = Double(latParam) else {
                Handlers.error(request, response, message: "lat must be a number")
                return
            }
            guard let lon = Double(lonParam) else {
                Handlers.error(request, response, message: "lon must be a number")
                return
            }

            let placename = try LocationToNameInfo().from(latitude: lat, longitude: lon)

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
            guard let latParam = request.param(name: "lat") else {
                Handlers.error(request, response, message: "lat must be specified")
                return                
            }
            guard let lonParam = request.param(name: "lon") else {
                Handlers.error(request, response, message: "lon must be specified")
                return
            }

            guard let lat = Double(latParam) else {
                Handlers.error(request, response, message: "lat must be a number")
                return
            }
            guard let lon = Double(lonParam) else {
                Handlers.error(request, response, message: "lon must be a number")
                return
            }

            let placename = try LocationToNameInfo().testFrom(latitude: lat, longitude: lon)

            let encodedData = try JSON(placename).rawData()
            response.setBody(string: String(data: encodedData, encoding: .utf8)!)
        } catch {
            Handlers.error(request, response, error)
        }
    }
}
