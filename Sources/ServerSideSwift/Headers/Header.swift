import Foundation

class Header {
    static let serverHeader = "Server: adrian-ensan-server"
    static let locationHeader = "Location: "
    static let cookieHeader = "Cookie: "
    static let setCookieHeader = "Set-Cookie: "


    static let httpDateFormater: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd LLL yyyy hh:mm:ss zzz"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        return dateFormatter
    }()
}
