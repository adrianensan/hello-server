import Foundation

public struct Request: CustomStringConvertible {
    
  public let method: Method
  public let url: String
  let host: String?
  public let cookies: [String: String]
  public let body: Data?
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
  private var headerString: String {
    return
    """
    \(method) \(url)
    Host: \(host ?? "Not Set")
    
    """
  }
  
  public var description: String {
    var string = headerString
    if let bodyString = bodyAsString { string += bodyString + .lineBreak }
    return string
  }
  
  var data: Data {
    var data = Data(headerString.utf8)
    if let body = body { data += body }
    return data
  }
}
