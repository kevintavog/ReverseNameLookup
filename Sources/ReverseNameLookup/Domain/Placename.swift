import Foundation


struct Placename : Encodable {
    let description: String
    let fullDescription: String
    let sites: [String]?
    let site: String?
    let city: String?
    let state: String?
    let countryCode: String?
    let countryName: String?

    public init(sites: [String]?, site: String?, city: String?, state: String?, countryCode: String?, countryName: String?, fullDescription: String) {
        self.sites = sites
        self.site = site
        self.city = city
        self.state = state
        self.countryCode = countryCode
        self.countryName = countryName
        self.fullDescription = fullDescription

        let nameComponents = [
            site,
            city, 
            state, 
            countryName]
        self.description = nameComponents.compactMap( { $0 }).joined(separator: ", ")
    }
}
