// swift-tools-version:4.0

import PackageDescription

let package = Package(
	name: "ReverseNameLookup",
	dependencies: [
		.package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
		.package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", from: "3.0.0"),
// Until SwiftyJSON master is Linux compatible, use the branch waiting to be merged
		.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.2.0"),
		.package(url: "https://github.com/FabrizioBrancati/Queuer.git", from: "1.3.1")
	],
    targets: [
        .target(
            name: "ReverseNameLookup",
            dependencies: ["PerfectHTTPServer", "PerfectCURL", "Queuer", "SwiftyJSON"])
    ]
)
