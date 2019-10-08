import Foundation

public class CookieBuilder: CustomStringConvertible {
  
  public var name: String
  public var value: String
  public var domain: String?
  public var path: String?
  public var secure: Bool = false
  public var httpOnly: Bool = false
  public var sameSite: Cookie.SameSiteType?
  private var expiry: TimeInterval?
  private var maxAge: Double?
  private var customValues: [String] = []
  
  public var finalizedCookie: Cookie { Cookie(name: name,
                                              value: value,
                                              domain: domain,
                                              path: path,
                                              secure: secure,
                                              httpOnly: httpOnly,
                                              sameSite: sameSite,
                                              expiry: expiry,
                                              customValues: customValues)}
  
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
  
  public var description: String { finalizedCookie.description }
}
