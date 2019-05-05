import PerfectHTTP

public func makeJSONRoutes(_ root: String = "/api/v1") -> Routes {
	var routes = Routes()

	// routes.add(method: .post, uri: "\(root)/save", handler: processSaveScore)
	routes.add(method: .get, uri: "\(root)/name", handler: Handlers.getName)
	routes.add(method: .get, uri: "\(root)/test", handler: Handlers.testName)
	routes.add(method: .get, uri: "\(root)/cached-name", handler: Handlers.getCachedName)

	return routes
}