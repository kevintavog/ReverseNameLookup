import Foundation

class AzureNameResolver {
    let baseAddress = "https://atlas.microsoft.com/search/address/reverse/json?subscription-key=%1$s&api-version=1.0&query=%2$lf,%3$lf&radius=500&language=en-US"

    func resolve(_ latitude: Double, _ longitude: Double, maxDistanceInMeters: Int) throws -> JSON? {
        var url = ""
        Config.azureSubscriptionKey.withCString {
            url = String(format: baseAddress, $0, latitude, longitude)
        }

        guard let data = try synchronousHttpGet(url) else {
            throw NameResolverError.NoDataReturned
        }

        return try JSON(data: data)
    }
}
