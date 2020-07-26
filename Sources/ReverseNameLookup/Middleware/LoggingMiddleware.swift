import Foundation
import Logging

import Vapor

final class LoggingMiddleware: Middleware {
    static let logger = Logger(label: "LoggingMiddleware")

    static public  var dateFormatter: DateFormatter = {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "en_US_POSIX")
        dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        dt.timeZone = TimeZone(secondsFromGMT: 0)
        return dt
    }()

    static public func info(_ msg: String) {
        LoggingMiddleware.logger.info("[\(LoggingMiddleware.dateFormatter.string(from: Date()))] \(msg)")        
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let start = Date()
        let response = next.respond(to: request)

        response.whenComplete { result in
            let duration = Int(start.timeIntervalSinceNow * -1000)
            var status = ""
            var responseLength = 0
            switch result {
                case .failure(let error):
                    status="\(error)"
                    break
                case .success(let response):
                    status = "\(response.status)"
                    responseLength = response.body.count
                    break
            }

            let startString = LoggingMiddleware.dateFormatter.string(from: start)
            var url = request.url.path
            if let q = request.url.query {
                url += "?\(q)"
            }
            let msg = "[\(startString)] \(request.method) \(url)"
                    + " status=\(status) duration_ms=\(duration)"
                    + " response_bytes=\(responseLength)"
            LoggingMiddleware.logger.info("\(msg)")
        }

        return response
    }
}
