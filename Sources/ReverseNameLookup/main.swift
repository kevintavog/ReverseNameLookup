import Vapor


do {
    var env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)
    let app = Application(env)

    // Oddly, invoking shutdown times out and reports an error (after an API call is made).
    // defer { app.shutdown() }
    try configure(app)
    try app.run()
} catch {
    print("Server failed: \(error)")
}
