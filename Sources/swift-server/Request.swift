import Foundation

enum Method {
    
    case get
    case post
    case any
    case unknown
    
    static func inferFrom(string: String) -> Method {
        switch string {
        case "get": return .get
        case "post": return .post
        default: return .unknown
        }
    }
}

class Request: CustomStringConvertible {
    
    var description: String {
        return
            """
            \(method) \(url)
            """
        
    }
    
    var method: Method
    var url: String
    
    init(method: Method, url: String) {
        self.method = method
        self.url = url
    }
}
