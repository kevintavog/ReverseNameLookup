import PerfectHTTP

func statusHandler(request: HTTPRequest, _ response: HTTPResponse) {
	response.setHeader(.contentType, value: "text/html")
	response.appendBody(string: "OK")
	response.completed()
}
