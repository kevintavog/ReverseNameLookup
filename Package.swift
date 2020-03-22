// swift-tools-version:5.1

import PackageDescription

let package = Package(
	name: "ReverseNameLookup",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.23"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", from: "4.0.1"),
		// .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .branch("master")),
		.package(url: "https://github.com/FabrizioBrancati/Queuer.git", from: "2.1.1")
	],
    targets: [
        .target(
            name: "ReverseNameLookup",
            dependencies: ["PerfectHTTPServer", "PerfectCURL", "Queuer"])
    ]
)
