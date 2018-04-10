enum Status {
    case ok
    case badRequest
    case notFound
    case movedPermanently
    case internalServerError
    
    var statusCode: Int {
        switch self {
        case                  .ok: return 200
        case          .badRequest: return 400
        case            .notFound: return 404
        case    .movedPermanently: return 301
        case .internalServerError: return 500
        }
    }
    
    var statusDescription: String {
        switch self {
        case                  .ok: return "OK"
        case          .badRequest: return "Bad Request"
        case            .notFound: return "Not Found"
        case    .movedPermanently: return "Moved Permanently"
        case .internalServerError: return "Internal Server Error"
        }
    }
    
    var string: String {
        return "\(statusCode) \(statusDescription)"
    }
}
