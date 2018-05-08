// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "ReverseNameLookup",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", from: "3.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
        .package(url: "https://github.com/duemunk/Async", from: "2.0.0")
	],
    targets: [
        .target(
            name: "ReverseNameLookup",
            dependencies: ["PerfectHTTPServer", "PerfectCURL", "SwiftyJSON", "Async"]),
    ]
)
