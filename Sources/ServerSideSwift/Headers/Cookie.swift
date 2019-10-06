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
  
  public var name: String
  public var value: String
  public var domain: String?
  public var path: String?
  public var secure: Bool
  public var httpOnly: Bool
  public var sameSite: SameSiteType?
  private var expiry: TimeInterval?
  private var maxAge: Double?
  private var customValues: [String]
  
  public init(name: String,
              value: String,
              expiry: TimeInterval? = nil,
              maxAge: Double? = nil,
              domain: String?,
              path: String?,
              httpOnly: Bool = false,
              secure: Bool = false,
              sameSite: SameSiteType? = nil) {
    self.name = name.filterNewlines
    self.value = value.filterNewlines
    self.expiry = expiry
    self.maxAge = maxAge
    self.domain = domain?.filterNewlines
    self.path = path?.filterNewlines
    self.secure = secure
    self.httpOnly = httpOnly
    self.sameSite = sameSite
    customValues = [String]()
  }
  
  mutating public func setExpiry(secondsFrom1970: TimeInterval) {
    expiry = secondsFrom1970
    maxAge = secondsFrom1970 - Date().timeIntervalSince1970
  }
  
  mutating public func setExpiry(secondsFromNow: Double) {
    expiry = Date().timeIntervalSince1970 + secondsFromNow
    maxAge = secondsFromNow
  }
  
  mutating public func addCustom(_ value: String) { customValues.append(value.filterNewlines) }
  
  public var description: String {
    var string: String = Header.setCookieHeader
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
