import Foundation

class Header {
  static let serverPrefix = "Server: adrian-ensan-server"
  static let locationPrefix = "Location: "
  static let cookiePrefix = "Cookie: "
  static let setCookiePrefix = "Set-Cookie: "
  static let lastModifiedPrefix = "Last-Modified: "
  static let hstsPrefix = "Strict-Transport-Security: max-age=31536000; includeSubDomains"
  static let contentTypePrefix = "Content-Type: "
  static let contentLengthPrefix = "Content-Length: "
  static let HostPrefix = "Host: "

  static let httpDateFormater: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss zzz"
    dateFormatter.timeZone = TimeZone(identifier: "GMT")
    return dateFormatter
  }()
}
