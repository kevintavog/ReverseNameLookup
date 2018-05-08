import Foundation
import SwiftyJSON

class Config
{
    private let _mapquestLookupKey: String
    private let _mapzenLookupKey: String
    private let _openCageDataLookupKey: String
    private let _elasticSearchUrl: String


    static var sharedInstance: Config
    {
        struct _Singleton {
            static let instance = Config()
        }
        return _Singleton.instance
    }

    private init() {
        var mapQKey = "mapquest_key"
        var mapZKey = "mapzen_key"
        var oCDKey = "OpenCageData_key"
        var eUrl = "elastic_url"

        var loadedFile = false
        if let data = try? Data(contentsOf: Config.fullLocationFilenameURL) {
            loadedFile = true
            if let json = try? JSON(data:data) {
                mapQKey = json["mapquestLookupKey"].stringValue
                mapZKey = json["mapzenLookupKey"].stringValue
                oCDKey = json["openCageDataLookupKey"].stringValue
                eUrl = json["elasticSearchUrl"].stringValue
            }
        }
        
        _mapquestLookupKey = mapQKey
        _mapzenLookupKey = mapZKey
        _openCageDataLookupKey = oCDKey
        _elasticSearchUrl = eUrl

        if !loadedFile {
            self.save()
        }
    }

    private func save() {
        do {
            var json = JSON()
            json["mapquestLookupKey"].string = _mapquestLookupKey
            json["mapzenLookupKey"].string = _mapzenLookupKey
            json["openCageDataLookupKey"].string = _openCageDataLookupKey
            json["elasticSearchUrl"].string = _elasticSearchUrl
            let jsonString: String = json.rawString()!
            try jsonString.write(to: Config.fullLocationFilenameURL, atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            print("Unable to save locations: \(error)")
        }
    }

    private static var fullLocationFilenameURL: URL {
        return FileManager.default.urls(
            for: .libraryDirectory, 
            in: .userDomainMask)[0].appendingPathComponent("Preferences").appendingPathComponent("rangic.ReverseNameLookup.config")
    }

    static var mapquestLookupKey: String
    {
        get { return Config.sharedInstance._mapquestLookupKey }
    }

    static var mapzenLookupKey: String
    {
        get { return Config.sharedInstance._mapzenLookupKey }
    }

    static var openCageDataLookupKey: String
    {
        get { return Config.sharedInstance._openCageDataLookupKey }
    }

    static var elasticSearchUrl: String
    {
        get { return Config.sharedInstance._elasticSearchUrl }
    }
}
