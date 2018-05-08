import Foundation
import PerfectCURL

enum SynchronouseHttpError : Swift.Error {
    case RequestFailed(String)
}

// Synchronously invoke a (JSON) POST to a url, with a given body, return the data or an error.
public func synchronousHttpPost(_ url: String, _ body: String) throws -> Data? {
    let data = body.data(using: .utf8, allowLossyConversion: false)!
    return try synchronousHttpPost(url, data)
}

// Synchronously invoke a (JSON) POST to a url, with a given body, return the data or an error.
public func synchronousHttpPost(_ url: String, _ body: Data) throws -> Data? {

    let response = try CURLRequest(
            url,
            .httpMethod(CURLRequest.HTTPMethod.post),
            .addHeader(CURLRequest.Header.Name.contentType, "application/json; charset=UTF-8"),
            .postData([UInt8](body)))
        .perform()

    if response.responseCode > 299 {
        throw SynchronouseHttpError.RequestFailed("status code: \(response.responseCode); \(response.bodyString)")
    }

    return response.bodyString.data(using: .utf8, allowLossyConversion: false)
}

// Synchronously invoke a GET to a url, return the data or an error.
public func synchronousHttpGet(_ url: String) throws -> Data? {

    let response = try CURLRequest(
            url,
            .httpMethod(CURLRequest.HTTPMethod.get))
        .perform()

    if response.responseCode > 299 {
        throw SynchronouseHttpError.RequestFailed("status code: \(response.responseCode); \(response.bodyString)")
    }

    return response.bodyString.data(using: .utf8, allowLossyConversion: false)
}
