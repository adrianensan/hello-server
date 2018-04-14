public enum Method {
    case get
    case head
    case post
    case put
    case delete
    case patch
    case options
    case any
    case unknown
    
    static func inferFrom(string: String) -> Method {
        switch string {
        case "get": return .get
        case "head": return .head
        case "post": return .post
        case "put": return .put
        case "delete": return .delete
        case "patch": return .patch
        case "options": return .options
        default: return .unknown
        }
    }
}
