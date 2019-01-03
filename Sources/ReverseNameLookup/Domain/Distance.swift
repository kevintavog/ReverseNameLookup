import Foundation

struct Distance {
    static public func areaOf(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let width = Distance.metersBetween(lat1, lon1, lat1, lon2)
        let height = Distance.metersBetween(lat1, lon1, lat2, lon1)
        return width * height
    }

    static public func metersBetween(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let lat1rad = lat1 * Double.pi/180
        let lon1rad = lon1 * Double.pi/180
        let lat2rad = lat2 * Double.pi/180
        let lon2rad = lon2 * Double.pi/180

        let dLat = lat2rad - lat1rad
        let dLon = lon2rad - lon1rad
        let a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1rad) * cos(lat2rad)
        let c = 2 * asin(sqrt(a))
        let R = 6372.8
        
        return (R * c) * 1000.0
    }
}
