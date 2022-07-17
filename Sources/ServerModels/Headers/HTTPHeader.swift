import Foundation

public enum Header {}
public extension Header {
  static let serverPrefix = "Server: Hello"
  static let locationPrefix = "Location: "
  static let datePrefix = "Date: "
  static let cookiePrefix = "Cookie: "
  static let setCookiePrefix = "Set-Cookie: "
  static let lastModifiedPrefix = "Last-Modified: "
  static let hstsPrefix = "Strict-Transport-Security: max-age=31536000; includeSubDomains"
  static let contentTypePrefix = "Content-Type: "
  static let contentLengthPrefix = "Content-Length: "
  static let contentEncodingPrefix = "Content-Encoding: "
  static let HostPrefix = "Host: "
  static let cacheControl = "Cache-Control: "
  static let connection = "Connection: "

  static let httpDateFormater: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, dd LLL yyyy HH:mm:ss zzz"
    dateFormatter.timeZone = TimeZone(identifier: "GMT")
    return dateFormatter
  }()
}
