import Foundation

struct ReverseNameLocation : Codable {
    var lat: Double
    var lon: Double
}

struct LocationNameInfo: Codable, CustomStringConvertible {
    var latitude: Double
    var longitude: Double

    var address: OSMAddress

    public init(latitude: Double, longitude: Double, address: OSMAddress) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }

    public var description: String {
        return "\(latitude), \(longitude); \(address)"
    }
}
