import Foundation

public struct Cookie: CustomStringConvertible {
    
  public enum SameSiteType {
    case strict
    case lax
    
    var description: String {
      switch self {
      case .strict: return "Strict"
      case .lax: return "Lax"
      }
    }
  }
  
  public let name: String
  public let value: String
  public let domain: String?
  public let path: String?
  public let secure: Bool
  public let httpOnly: Bool
  public let sameSite: SameSiteType?
  public let expiry: TimeInterval?
  public let customValues: [String]
  
  public var maxAge: TimeInterval? {
    if let expiry = expiry { return expiry - Date().timeIntervalSince1970 }
    return nil
  }
  
  public var description: String {
    var string: String = Header.setCookiePrefix
    string += "\(name)=\(value)"
    if let expiry = expiry { string += "Expiry=\(Header.httpDateFormater.string(from: Date(timeIntervalSince1970: expiry)))" }
    if let maxAge = maxAge { string += "Max-Age=\(maxAge)" }
    if let domain = domain { string += "Domain=\(domain)" }
    if let path = path { string += "Path=\(path)" }
    if httpOnly { string += "; HttpOnly)" }
    if secure { string += "; secure" }
    if let sameSite = sameSite { string += "; \(sameSite.description)" }
    for custom in customValues { string += "; \(custom)" }
    return string.filterNewlines
  }
}
