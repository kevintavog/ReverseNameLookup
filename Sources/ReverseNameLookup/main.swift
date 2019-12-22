import PerfectLib
import PerfectHTTP
import PerfectHTTPServer


let server = HTTPServer()

let logger = RangicLogger()
server.setRequestFilters([(logger, .high)])
server.setResponseFilters([(logger, .low)])

var routes = makeJSONRoutes()
routes.add(method: .get, uri: "/status", handler: statusHandler)

server.addRoutes(routes)
server.serverPort = 8888

do {
	Logger.log("Using ElasticSearch host: \(Config.elasticSearchUrl)")
	try server.start()
} catch {
	fatalError("\(error)")
}
