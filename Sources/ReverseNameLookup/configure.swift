import Vapor

public func configure(_ app: Application) throws {
    app.middleware = .init()
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    app.http.server.configuration.port = 8888
    app.http.server.configuration.hostname = "0.0.0.0"
    try routes(app)
}
