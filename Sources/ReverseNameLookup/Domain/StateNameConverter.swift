
struct StateNameConverter {
    static func toName(_ countryCode: String, _ state: String?) -> String? {
        guard let stateName = state else {
            return state
        }
        if countryCode.lowercased() == "mx" {
            return nil
        }

        guard let stateMap = codeToStateMap[countryCode.lowercased()] else {
            return state
        }
        guard let newName = stateMap[stateName.lowercased()] else {
            Logger.log("WARNING: Missing entry for '\(stateName)'")
            return state
        }

        return newName
    }

    static let codeToStateMap = [
        "ca": [
            "alberta": "AB",
            "british columbia": "BC",
            "manitoba": "MB",
            "new brunswick": "NB",
            "newfoundland and labrador": "NL",
            "northwest terrotories": "NT",
            "nova scotia": "NS",
            "nunavut": "NU",
            "ontario": "ON",
            "prince edward island": "PE",
            "quebec": "QC",
            "saskatchewan": "SK",
            "yukon": "yt",
        ],
        "us": [
            "alabama": "AL",
            "alaska": "AK",
            "arizona": "AZ",
            "arkansas": "AR",
            "california": "CA",
            "colorado": "CO",
            "connecticut": "CT",
            "deleware": "DE",
            "district of columbia": "DC",
            "florida": "FL",
            "georgia": "GA",
            "hawaii": "HI",
            "idaho": "ID",
            "illinois": "IL",
            "indiana": "IN",
            "iowa": "IA",
            "kansas": "KS",
            "kentucky": "KY",
            "louisian": "LA",
            "maine": "ME",
            "maryland": "MD",
            "massachusetts": "MA",
            "michigan": "MI",
            "minnesota": "MN",
            "mississippi": "MS",
            "missouri": "MO",
            "montana": "MT",
            "nebraska": "NE",
            "nevada": "NV",
            "new hampshire": "NH",
            "new jersey": "NJ",
            "new mexico": "NM",
            "new york": "NY",
            "north carolina": "NC",
            "north dakota": "ND",
            "ohio": "OH",
            "oklahoma": "OK",
            "oregon": "OR",
            "pennsylvania": "PA",
            "rhode island": "RI",
            "south carolina": "SC",
            "south dakota": "SD",
            "tennessee": "TN",
            "texas": "TX",
            "utah": "UT",
            "vermont": "VT",
            "virginia": "VA",
            "washington": "WA",
            "west virginia": "WV",
            "wisconsin": "WI",
            "wyoming": "WY"
        ]
    ]
}