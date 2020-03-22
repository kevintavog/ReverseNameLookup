import Foundation

class Config
{
    private let _azureSubscriptionKey: String
    private let _mapquestLookupKey: String
    private let _mapzenLookupKey: String
    private let _openCageDataLookupKey: String
    private let _elasticSearchUrl: String
    private let _foursquareClientId: String
    private let _foursquareClientSecret: String


    static var sharedInstance: Config
    {
        struct _Singleton {
            static let instance = Config()
        }
        return _Singleton.instance
    }

    private init() {
        var azureSubscriptionKey = "azure_subscription_key"
        var mapQKey = "mapquest_key"
        var mapZKey = "mapzen_key"
        var oCDKey = "OpenCageData_key"
        var eUrl = "elastic_url"
        var fourClientId = "foursquare_clientid"
        var fourClientSecret = "foursquare_clientsecret"

        var loadedFile = false
        if let data = try? Data(contentsOf: Config.fullLocationFilenameURL) {
            loadedFile = true
            if let json = try? JSON(data:data) {
                azureSubscriptionKey = json["azureSubscriptionKey"].stringValue
                mapQKey = json["mapquestLookupKey"].stringValue
                mapZKey = json["mapzenLookupKey"].stringValue
                oCDKey = json["openCageDataLookupKey"].stringValue
                eUrl = json["elasticSearchUrl"].stringValue
                fourClientId = json["foursquareClientId"].stringValue
                fourClientSecret = json["foursquareClientSecret"].stringValue
            }
        }

        _azureSubscriptionKey = azureSubscriptionKey
        _mapquestLookupKey = mapQKey
        _mapzenLookupKey = mapZKey
        _openCageDataLookupKey = oCDKey
        _elasticSearchUrl = eUrl
        _foursquareClientId = fourClientId
        _foursquareClientSecret = fourClientSecret

        if !loadedFile {
            self.save()
        }
    }

    private func save() {
        do {
            var json = JSON()
            json["azureSubscriptionKey"].string = _azureSubscriptionKey
            json["mapquestLookupKey"].string = _mapquestLookupKey
            json["mapzenLookupKey"].string = _mapzenLookupKey
            json["openCageDataLookupKey"].string = _openCageDataLookupKey
            json["elasticSearchUrl"].string = _elasticSearchUrl
            json["foursquareClientId"].string = _foursquareClientId
            json["foursquareClientSecret"].string = _foursquareClientSecret
            let jsonString: String = json.rawString()!
            try jsonString.write(to: Config.fullLocationFilenameURL, atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            Logger.log("Unable to save locations: \(error)")
        }
    }

#if os(OSX)
    private static var fullLocationFilenameURL: URL {
        return FileManager.default.urls(
            for: .libraryDirectory, 
            in: .userDomainMask)[0].appendingPathComponent("Preferences").appendingPathComponent("rangic.ReverseNameLookup.config")
    }
#elseif os(Linux)
    private static var fullLocationFilenameURL: URL {
        return URL(fileURLWithPath: "/etc/reversenamelookup.config")
    }
#endif

    static var azureSubscriptionKey: String {
        get { return Config.sharedInstance._azureSubscriptionKey }
    }

    static var mapquestLookupKey: String {
        get { return Config.sharedInstance._mapquestLookupKey }
    }

    static var mapzenLookupKey: String {
        get { return Config.sharedInstance._mapzenLookupKey }
    }

    static var openCageDataLookupKey: String {
        get { return Config.sharedInstance._openCageDataLookupKey }
    }

    static var elasticSearchUrl: String {
        get { return Config.sharedInstance._elasticSearchUrl }
    }

    static var foursquareClientId: String {
        get { return Config.sharedInstance._foursquareClientId }
    }

    static var foursquareClientSecret: String {
        get { return Config.sharedInstance._foursquareClientSecret }
    }
}
