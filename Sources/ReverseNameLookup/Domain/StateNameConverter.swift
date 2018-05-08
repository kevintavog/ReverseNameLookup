
struct StateNameConverter {
    static func toName(_ addressInfo: OSMAddress) -> String? {
        guard let countryCode = addressInfo.country_code, let stateName = addressInfo.state else {
            return addressInfo.state
        }
        guard let stateMap = codeToStateMap[countryCode] else {
            return addressInfo.state
        }

        guard let state = stateMap[stateName.lowercased()] else {
            print("WARNING: Missing entry for '\(stateName)'")
            return addressInfo.state
        }

        return state
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