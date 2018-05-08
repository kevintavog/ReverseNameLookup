import Foundation

import PerfectLib
import PerfectHTTP


public class RangicLogger: HTTPRequestFilter, HTTPResponseFilter {

	static let serviceErrorMessageKey = "serviceErrorMessage"

    let dateFormatter: DateFormatter

    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }

    /// Implementation HTTPRequestFilter
	public func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {

		request.scratchPad["start"] = Date()
		callback(.continue(request, response))
	}


    /// Implement HTTPResponseFilter
	public func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		let method = response.request.method
		let path = response.request.path
		let start = response.request.scratchPad["start"] as? Date ?? Date()
        let paramsString = (response.request.queryParams.flatMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")

		let status = response.status.code
		let length = response.bodyBytes.count


		let duration = Int(start.timeIntervalSinceNow * -1000)
        let startString = dateFormatter.string(from: start)

		var extra = ""
		if let serviceErrorMessage = response.request.scratchPad[RangicLogger.serviceErrorMessageKey] {
			extra += "serviceError=\"\(serviceErrorMessage)\""
		}

		for (key, value) in response.request.scratchPad {
			if key != "start" && key != RangicLogger.serviceErrorMessageKey && !key.starts(with: "_") {
				extra += " \(key)=\"\(value)\""
			}
		}

        Logger.log("time=\"\(startString)\" duration_ms=\(duration) status=\(status) " +
			"method=\(method) path=\(path) params=\"\(paramsString)\" response_length=\(length) \(extra)")

		callback(.continue)
	}

    /// Implement HTTPResponseFilter
	public func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		callback(.continue)
	}
}
