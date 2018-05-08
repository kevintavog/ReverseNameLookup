import PerfectHTTP

extension Handlers {

	static func error(_ request: HTTPRequest, _ response: HTTPResponse, _ error: Error) {
        Handlers.error(request, response, message: "\(error)")
    }

	static func error(_ request: HTTPRequest, _ response: HTTPResponse, message: String, code: HTTPResponseStatus = .badRequest) {
		do {
			response.status = code
			request.scratchPad[RangicLogger.serviceErrorMessageKey] = message
			try response.setBody(json: ["error": "\(message)"])
		} catch {
			print(error)
		}
		response.completed()
	}
}