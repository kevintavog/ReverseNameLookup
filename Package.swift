// swift-tools-version:5.0

import PackageDescription

let package = Package(
	name: "ReverseNameLookup",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.23"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", from: "4.0.1"),
		.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
		.package(url: "https://github.com/FabrizioBrancati/Queuer.git", from: "2.1.0")
	],
    targets: [
        .target(
            name: "ReverseNameLookup",
            dependencies: ["PerfectHTTPServer", "PerfectCURL", "Queuer", "SwiftyJSON"])
    ]
)
