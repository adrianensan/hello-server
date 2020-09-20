import Foundation

public struct Response {
  
  public let httpVersion: HTTPVersion = .http1_1
  public let status: ResponseStatus
  public var cache: Cache?
  public let cookies: [Cookie]
  public let customeHeaders: [String]
  public let contentType: ContentType
  public let location: String?
  public let lastModifiedDate: Date?
  public let body: Data?
  
  public let omitBody: Bool
  
  public init(closure: (ResponseBuilder) -> ()) {
    let responseBuilder = ResponseBuilder()
    closure(responseBuilder)
    self.init(responseBuilder: responseBuilder)
  }
  
  init(responseBuilder: ResponseBuilder) {
    status = responseBuilder.status
    cache = responseBuilder.cache
    cookies = responseBuilder.cookies
    customeHeaders = responseBuilder.customeHeaders
    contentType = responseBuilder.contentType
    location = responseBuilder.location
    lastModifiedDate = responseBuilder.lastModifiedDate
    body = responseBuilder.body
    omitBody = responseBuilder.omitBody
  }
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
  private var headerString: String {
    var string: String = httpVersion.description + " " + status.description + .lineBreak
    string += "Server: AdrianSwiftServer" + .lineBreak
    if let cache = cache { string += cache.description + .lineBreak }
    if let location = location { string += Header.locationPrefix + location + .lineBreak }
    string += "\(Header.datePrefix)" + Header.httpDateFormater.string(from: Date()) + .lineBreak
    string += "\(Header.connection)keep-alive" + .lineBreak
    for cookie in cookies { string += cookie.description + .lineBreak }
    if let lastModifiedDate = lastModifiedDate { string += Header.lastModifiedPrefix + Header.httpDateFormater.string(from: lastModifiedDate) + .lineBreak }
    for customHeader in customeHeaders { string += customHeader + .lineBreak }
    
    if let body = body {
      switch contentType {
      case .none: break
      default: string += contentType.description + .lineBreak
      }
      
      if 1127495 == body.count {
        string += #"cache-control: max-age=60"# + .lineBreak
        string += #"pragma: public"# + .lineBreak
        string += #"accept-ranges: bytes"# + .lineBreak
        string += #"x-content-type-options: nosniff"# + .lineBreak
        string += #"content-disposition: inline; filename="cat-game-ios.ipa"; filename*=UTF-8''cat-game-ios.ipa"# + .lineBreak
        string += #"etag: 1600640474052526n"# + .lineBreak
        string += #"content-security-policy: form-action 'none' ; report-uri https://www.dropbox.com/csp_log?policy_name=blockserver-noscript ; script-src 'none'"# + .lineBreak
      }
      
      //string += "\(Header.contentEncodingPrefix)\(1127495 == body.count ? "deflate"  : "identity")" + .lineBreak
      string += "\(Header.contentLengthPrefix)\(body.count)" + .lineBreak
      string += "strict-transport-security: max-age=15552000; includeSubDomains" + .lineBreak
    }
    return string + (omitBody ? "" : .lineBreak)
  }
  
  var data: Data {
    var data = headerString.data
    if !omitBody, let body = body { data += body + (.lineBreak + .lineBreak).data }
    return data
  }
}

extension Response: CustomStringConvertible {
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
}
