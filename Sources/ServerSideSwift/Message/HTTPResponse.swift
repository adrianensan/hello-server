import Foundation

import ServerModels

extension HTTPResponse {
  static var serverError: HTTPResponse { HTTPResponse(status: .internalServerError) }
}

public struct HTTPResponse {
  
  public let httpVersion: HTTPVersion = .http1_1
  public let status: HTTPResponseStatus
  public var cache: Cache?
  public let cookies: [Cookie]
  public let customeHeaders: [String]
  public let contentType: ContentType
  public let location: String?
  public let lastModifiedDate: Date?
  public let body: Data?
  
  public let omitBody: Bool
  
  public init(status: HTTPResponseStatus,
              cache: Cache? = nil,
              cookies: [Cookie] = [],
              customeHeaders: [String] = [],
              contentType: ContentType = .none,
              location: String? = nil,
              lastModifiedDate: Date? = nil,
              body: Data? = nil,
              omitBody: Bool = true) {
    self.status = status
    self.cache = cache
    self.cookies = cookies
    self.customeHeaders = customeHeaders
    self.contentType = contentType
    self.location = location
    self.lastModifiedDate = lastModifiedDate
    self.body = body
    self.omitBody = omitBody
  }
  
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
  
  public var bodyAsString: String? {
    if let body = body {
      return String(data: body, encoding: .utf8)
    } else {
      return nil
    }
  }
  
  private var headerString: String {
    var string: String = httpVersion.description + " " + status.description + .lineBreak
    string += "Server: Hello" + .lineBreak
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
      
      string += "\(Header.contentEncodingPrefix)identity" + .lineBreak
      string += "\(Header.contentLengthPrefix)\(body.count)" + .lineBreak
    } else {
      string += "\(Header.contentLengthPrefix)0" + .lineBreak
    }
    string += "strict-transport-security: max-age=15552000; includeSubDomains" + .lineBreak
    return string + .lineBreak
  }
  
  var data: Data {
    var data = headerString.data
    if !omitBody, let body = body { data += body }
    return data
  }
}

extension HTTPResponse: CustomStringConvertible {
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
}
