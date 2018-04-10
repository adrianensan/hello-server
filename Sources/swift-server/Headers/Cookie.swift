import Foundation

struct Cookie: CustomStringConvertible {
    
    enum SameSiteType {
        case none
        case strict
        case lax
        
        var description: String {
            switch self {
            case .strict: return "Strict"
            case .lax: return "Lax"
            default: return ""
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
    private var sameSite: SameSiteType
    private var customValues: [String]
    
    init(name: String, value: String,
         expiry: TimeInterval? = nil, maxAge: Double? = nil, domain: String?, path: String?,
         httpOnly: Bool = false, secure: Bool = false, sameSite: SameSiteType = .none) {
        self.name = name.filterNewlines
        self.value = value.filterNewlines
        self.expiry = expiry
        self.maxAge = maxAge
        self.domain = domain
        self.path = path
        self.secure = secure
        self.httpOnly = httpOnly
        self.sameSite = sameSite
        customValues = [String]()
    }
    
    mutating func setName(_ val: String) { name = val }
    mutating func setValue(_ val: String) { value = val }
    mutating func setExpiry(timeIntervalSince1970: TimeInterval) { expiry = timeIntervalSince1970 }
    mutating func setMaxAge(seconds: Double) { maxAge = seconds }
    mutating func setDomain(_ val: String) { domain = val }
    mutating func setPath(_ val: String) { path = val }
    mutating func setSecure(_ val: Bool) { secure = val }
    mutating func setHTTPOnly(_ val: Bool) { httpOnly = val }
    mutating func setSameSite(_ val: SameSiteType) { sameSite = val }
    mutating func addCustom(_ value: String) { customValues.append(value.filterNewlines) }
    
    var description: String {
        var string: String = Header.setCookieHeader
        string += "\(name)=\(value)"
        if let expiry = expiry { string += "Expiry=\(Header.httpDateFormater.string(from: Date(timeIntervalSince1970: expiry)))" }
        if let maxAge = maxAge { string += "Max-Age=\(maxAge)" }
        if let domain = domain { string += "Domain=\(domain)" }
        if let path = path { string += "Path=\(path)" }
        if httpOnly { string += "; HttpOnly)" }
        if secure { string += "; secure" }
        if sameSite != .none { string += "; \(sameSite.description)" }
        for custom in customValues { string += "; \(custom)" }
        return string
    }
}
