import Foundation
import Logging

import Vapor

final class LoggingMiddleware: Middleware {
    static let logger = Logger(label: "LoggingMiddleware")

    let dateFormatter: DateFormatter

    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
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

            let startString = self.dateFormatter.string(from: start)
            let msg = "[\(startString)] \(request.method) \(request.url.path)"
                    + " status=\(status) duration_ms=\(duration)"
                    + " response_bytes=\(responseLength)"
            LoggingMiddleware.logger.info("\(msg)")
        }

        return response
    }
}
