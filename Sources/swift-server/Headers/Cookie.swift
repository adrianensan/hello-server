import Foundation

struct Cookie: CustomStringConvertible {
    static let httpOnlyflag: String = "HttpOnly"
    static let secureFlag: String = "secure"
    static let sameSiteFlag: String = "sameSite"
    
    private let name: String
    private let value: String
    private var customValues: [String]
    
    var isHTTPOnly: Bool
    var isSecure: Bool
    var isSameSite: Bool
    
    init(name: String, value: String, httpOnly: Bool = false, sameSite: Bool = false, secure: Bool = false) {
        self.name = name.filterNewlines
        self.value = value.filterNewlines
        isHTTPOnly = httpOnly
        isSameSite = sameSite
        isSecure = secure
        customValues = [String]()
    }
    
    mutating func addCustom(_ value: String) {
        customValues.append(value.filterNewlines)
    }
    
    var description: String {
        var string: String = setCookieHeader
        string += "\(name)=\(value)"
        if isHTTPOnly { string += "; \(Cookie.httpOnlyflag)" }
        if isSecure { string += "; \(Cookie.secureFlag)" }
        if isSameSite { string += "; \(Cookie.sameSiteFlag)" }
        return string
    }
}
