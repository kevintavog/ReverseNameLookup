
struct CountryCodeConverter {
    static func toName(code: String?) -> String? {
        guard let c = code else {
            return nil
        }
        return codeToName[c]
    }


    static let codeToName = [
        "gb": "GBR",
        "us": "USA"
    ]
}