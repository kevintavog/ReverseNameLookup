// swift-tools-version:5.2

import PackageDescription

let package = Package(
	name: "ReverseNameLookup",
    platforms: [
       .macOS(.v10_15)
    ],
	dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.14.0")),
        .package(url: "https://github.com/dduan/Just.git",  from: "0.8.0"),
		.package(url: "https://github.com/FabrizioBrancati/Queuer.git", from: "2.1.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.14.0"),

        // .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMajor(from: "1.1.0")),
	],
    targets: [
        .target(
            name: "ReverseNameLookup",
            dependencies: [
                "Just",
				"Queuer", 
				"SwiftyJSON",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
				.product(name: "Vapor", package: "vapor")
			]),
        .target(
            name: "SwiftyJSON",
            dependencies: [
			]),
    ]
)
