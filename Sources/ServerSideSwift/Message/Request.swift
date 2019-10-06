import Foundation

public struct Request: CustomStringConvertible {
    
  public let method: Method
  public let url: String
  let host: String?
  public let cookies: [String: String]
  public let body: Data?
  
  public var bodyAsString: String? { if let body = body { return String(data: body, encoding: .utf8) } else { return nil } }
  
  public var description: String {
    return
      """
      \(method) \(url)
      Host: \(host ?? "Not Set")
       
      \(bodyAsString ?? "")
      """
  }
}
