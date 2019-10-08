import Foundation

public struct Request {
    
  public let httpVersion: HTTPVersion = .http1_1
  public let method: Method
  public let url: String
  let host: String?
  public let cookies: [String: String]
  public let body: Data?
  
  public init(_ builder: (RequestBuilder) -> Void) {
    let requestBuilder = RequestBuilder()
    builder(requestBuilder)
    self.init(requestBuilder: requestBuilder)
  }
  
  init(requestBuilder: RequestBuilder) {
    method = requestBuilder.method
    url = requestBuilder.url
    host = requestBuilder.host
    cookies = requestBuilder.cookies
    body = requestBuilder.body
  }
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
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

extension Request: CustomStringConvertible {
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
}
