
struct CountryCodeConverter {
    static func toName(code: String?) -> String? {
        guard let c = code else {
            return nil
        }
        return codeToName[c.lowercased()]
    }


    static let codeToName = [
        "us": "USA"
    ]
}