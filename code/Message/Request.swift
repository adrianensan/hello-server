import Foundation

import HelloCore

public struct RawHTTPRequest {
    
  public var clientAddress: NetworkAddress
  public let httpVersion: HTTPVersion = .http1_1
  public let method: HTTPMethod
  public let url: String
  var host: String? { headers["host"] }
  public let headers: [String: String]
  public let cookies: [String: String]
  public let body: Data?
  
  init(requestBuilder: HTTPRequestBuilder) {
    clientAddress = requestBuilder.clientAddress
    method = requestBuilder.method
    url = requestBuilder.url
    headers = requestBuilder.headers
    cookies = requestBuilder.cookies
    body = requestBuilder.body
  }
  
  public var bodyAsString: String? {
    if let body = body {
      return String(data: body, encoding: .utf8)
    } else {
      return nil
    }
  }
  
  private var headerString: String {
    var string: String = method.description + " " + url.description + " " + httpVersion.description + .lineBreak
    string += Header.HostPrefix + (host ?? "Not Set") + .lineBreak
    string += "Accept-Encoding: identity" + .lineBreak
    string += "Connection: keep-alive" + .lineBreak
    
    return string + .lineBreak
  }
  
  var data: Data {
    var data = headerString.data
    if let body = body { data += body + (.lineBreak + .lineBreak).data }
    return data
  }
}

extension RawHTTPRequest: CustomStringConvertible {
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
}
