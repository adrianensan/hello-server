import Foundation

public class CookieBuilder {
  
  public var name: String
  public var value: String
  public var domain: String?
  public var path: String?
  public var secure: Bool = false
  public var httpOnly: Bool = false
  public var sameSite: Cookie.SameSiteType?
  var expiry: TimeInterval?
  private var maxAge: Double?
  var customValues: [String] = []
  
  public var cookie: Cookie { Cookie(cookieBuilder: self) }
  
  public init(name: String, value: String) {
    self.name = name
    self.value = value
  }
  
  public func setExpiry(secondsFrom1970: TimeInterval) {
    expiry = secondsFrom1970
    maxAge = secondsFrom1970 - Date().timeIntervalSince1970
  }
  
  public func setExpiry(secondsFromNow: Double) {
    expiry = Date().timeIntervalSince1970 + secondsFromNow
    maxAge = secondsFromNow
  }
  
  public func addCustom(_ value: String) { customValues.append(value) }
}

extension CookieBuilder: CustomStringConvertible { public var description: String { cookie.description } }
