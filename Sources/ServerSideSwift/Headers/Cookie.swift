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
  
  private var name: String
  private var value: String
  private var expiry: TimeInterval?
  private var maxAge: Double?
  private var domain: String?
  private var path: String?
  private var secure: Bool
  private var httpOnly: Bool
  private var sameSite: SameSiteType?
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
  
  mutating public func setName(_ val: String) { name = val.filterNewlines }
  mutating public func setValue(_ val: String) { value = val.filterNewlines }
  mutating public func setExpiry(timeIntervalSince1970: TimeInterval) {
    expiry = timeIntervalSince1970
    maxAge = timeIntervalSince1970 - Date().timeIntervalSince1970
  }
  mutating public func setExpiry(secondsFromNow: Double) {
    expiry = Date().timeIntervalSince1970 + secondsFromNow
    maxAge = secondsFromNow
  }
  mutating public func setDomain(_ val: String) { domain = val.filterNewlines }
  mutating public func setPath(_ val: String) { path = val.filterNewlines }
  mutating public func setSecure(_ val: Bool) { secure = val }
  mutating public func setHTTPOnly(_ val: Bool) { httpOnly = val }
  mutating public func setSameSite(_ val: SameSiteType) { sameSite = val }
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
