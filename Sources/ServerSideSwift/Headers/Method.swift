public enum Method: CustomStringConvertible {
  case get
  case head
  case post
  case put
  case delete
  case patch
  case options
  case any
  case unknown
  
  static func infer(from string: String) -> Method {
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
  
  public var description: String {
    switch self {
    case .get: return "GET"
    case .head: return "HEAD"
    case .post: return "POST"
    case .put: return "PUT"
    case .delete: return "DELETE"
    case .patch: return "PATCH"
    case .options: return "OPTIONS"
    default: return "UNKOWN"
    }
  }
}
