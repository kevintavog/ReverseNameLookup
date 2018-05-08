import PackageDescription
let package = Package(
	name: "ReverseNameLookup",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 3),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", majorVersion: 3),
        .Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", majorVersion: 4),
        .Package(url: "https://github.com/duemunk/Async", majorVersion: 2)
	]
)
