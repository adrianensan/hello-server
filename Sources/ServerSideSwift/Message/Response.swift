import Foundation

public struct Response: CustomStringConvertible {

  public let httpVersion: HTTPVersion = .http1_1
  public let status: ResponseStatus
  public let cookies: [Cookie]
  public let customeHeaders: [String]
  public let contentType: ContentType
  public let location: String?
  public let lastModifiedDate: Date?
  public let omitBody: Bool = false
  public let body: Data?
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
  private var headerString: String {
    var string: String = httpVersion.description + " " + status.description + .lineBreak
    
    if let location = location { string += Header.locationPrefix + location + .lineBreak }
    for cookie in cookies { string += cookie.description + .lineBreak }
    if let date = lastModifiedDate { string += Header.lastModifiedPrefix + Header.httpDateFormater.string(from: date) + .lineBreak }
    for customHeader in customeHeaders { string += customHeader + .lineBreak }
    
    if let body = body {
      switch contentType {
      case .none: break
      default: string += contentType.description + .lineBreak
      }
      
      string += "\(Header.contentLengthPrefix)\(body.count)" + .lineBreak
    }
    return string + .lineBreak
  }
  
  var data: Data {
    var data = Data(headerString.utf8)
    if let body = body { data += body + Data((.lineBreak + .lineBreak).utf8) }
    return data
  }
  
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
}
