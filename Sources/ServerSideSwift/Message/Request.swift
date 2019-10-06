import Foundation

public struct Request: CustomStringConvertible {
    
  public let httpVersion: HTTPVersion = .http1_1
  public let method: Method
  public let url: String
  let host: String?
  public let cookies: [String: String]
  public let body: Data?
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
  private var headerString: String {
    var string: String = method.description + " " + url.description + " " + httpVersion.description + .lineBreak
    string += Header.HostPrefix + (host ?? "Not Set") + .lineBreak
    string += "Accept-Encoding: identity" + .lineBreak
    string += "Connection: keep-alive" + .lineBreak
    
    return string + .lineBreak
  }
  
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
  
  var data: Data {
    var data = Data(headerString.utf8)
    if let body = body { data += body + Data((.lineBreak + .lineBreak).utf8) }
    return data
  }
}
