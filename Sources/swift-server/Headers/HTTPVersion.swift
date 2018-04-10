enum HTTPVersion {
    case http1_0
    case http1_1
    case http2_0
    
    static let baseString = "HTTP/"
    
    var string: String {
        switch self {
        case .http1_0: return HTTPVersion.baseString + "1.0"
        case .http1_1: return HTTPVersion.baseString + "1.1"
        case .http2_0: return HTTPVersion.baseString + "2.0"
        }
    }
}
