public enum ResponseStatus: CustomStringConvertible {
    case `continue`
    case switchingProtocols
    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multipleChoices
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case temporaryRedirect
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case requestEntityTooLarge
    case requestURITooLong
    case unsupportedMediaType
    case requestedRangeNotSatisfiable
    case expectationFailed
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case custom(code: Int, message: String)
    
    public var statusCode: Int {
        switch self {
        case                     .continue: return 100
        case           .switchingProtocols: return 101
        case                           .ok: return 200
        case                      .created: return 201
        case                     .accepted: return 202
        case  .nonAuthoritativeInformation: return 203
        case                    .noContent: return 204
        case                 .resetContent: return 205
        case               .partialContent: return 206
        case              .multipleChoices: return 300
        case             .movedPermanently: return 301
        case                        .found: return 302
        case                     .seeOther: return 303
        case                  .notModified: return 304
        case                     .useProxy: return 305
        case            .temporaryRedirect: return 307
        case                   .badRequest: return 400
        case                 .unauthorized: return 401
        case              .paymentRequired: return 402
        case                    .forbidden: return 403
        case                     .notFound: return 404
        case             .methodNotAllowed: return 405
        case                .notAcceptable: return 406
        case  .proxyAuthenticationRequired: return 407
        case               .requestTimeout: return 408
        case                     .conflict: return 409
        case                         .gone: return 410
        case               .lengthRequired: return 411
        case           .preconditionFailed: return 412
        case        .requestEntityTooLarge: return 413
        case            .requestURITooLong: return 414
        case         .unsupportedMediaType: return 415
        case .requestedRangeNotSatisfiable: return 416
        case            .expectationFailed: return 417
        case          .internalServerError: return 500
        case               .notImplemented: return 501
        case                   .badGateway: return 502
        case           .serviceUnavailable: return 503
        case               .gatewayTimeout: return 504
        case      .httpVersionNotSupported: return 505
        case          .custom(let code, _): return code
        }
    }
    
    public var statusDescription: String {
        switch self {
        case                     .continue: return "Continue"
        case           .switchingProtocols: return "Switching Protocols"
        case                           .ok: return "OK"
        case                      .created: return "Created"
        case                     .accepted: return "Accepted"
        case  .nonAuthoritativeInformation: return "Non-Authoritative Information"
        case                    .noContent: return "No Content"
        case                 .resetContent: return "Reset Content"
        case               .partialContent: return "Partial Content"
        case              .multipleChoices: return "Multiple Choices"
        case             .movedPermanently: return "Moved Permanently"
        case                        .found: return "Found"
        case                     .seeOther: return "See Other"
        case                  .notModified: return "Not Modified"
        case                     .useProxy: return "Use Proxy"
        case            .temporaryRedirect: return "Temporary Redirect"
        case                   .badRequest: return "Bad Request"
        case                 .unauthorized: return "Unauthorized"
        case              .paymentRequired: return "Payment Required"
        case                    .forbidden: return "Forbidden"
        case                     .notFound: return "Not Found"
        case             .methodNotAllowed: return "Method Not Allowed"
        case                .notAcceptable: return "Not Acceptable"
        case  .proxyAuthenticationRequired: return "Proxy Authentication Required"
        case               .requestTimeout: return "Request Timeout"
        case                     .conflict: return "Conflict"
        case                         .gone: return "Gone"
        case               .lengthRequired: return "Length Required"
        case           .preconditionFailed: return "Precondition Failed"
        case        .requestEntityTooLarge: return "Request Entity Too Large"
        case            .requestURITooLong: return "Request-URI Too Long"
        case         .unsupportedMediaType: return "Unsupported Media Type"
        case .requestedRangeNotSatisfiable: return "Requested Range Not Satisfiable"
        case            .expectationFailed: return "Expectation Failed"
        case          .internalServerError: return "Internal Server Error"
        case               .notImplemented: return "Not Implemented"
        case                   .badGateway: return "Bad Gateway"
        case           .serviceUnavailable: return "Service Unavailable"
        case               .gatewayTimeout: return "Gateway Timeout"
        case      .httpVersionNotSupported: return "HTTP Version Not Supported"
        case       .custom(_, let message): return message
        }
    }
    
    static func from(code: Int) -> ResponseStatus {
        switch code {
        case 100: return .continue
        case 101: return .switchingProtocols
        case 200: return .ok
        case 201: return .created
        case 202: return .accepted
        case 203: return .nonAuthoritativeInformation
        case 204: return .noContent
        case 205: return .resetContent
        case 206: return .partialContent
        case 300: return .multipleChoices
        case 301: return .movedPermanently
        case 302: return .found
        case 303: return .seeOther
        case 304: return .notModified
        case 305: return .useProxy
        case 307: return .temporaryRedirect
        case 400: return .badRequest
        case 401: return .unauthorized
        case 402: return .paymentRequired
        case 403: return .forbidden
        case 404: return .notFound
        case 405: return .methodNotAllowed
        case 406: return .notAcceptable
        case 407: return .proxyAuthenticationRequired
        case 408: return .requestTimeout
        case 409: return .conflict
        case 410: return .gone
        case 411: return .lengthRequired
        case 412: return .preconditionFailed
        case 413: return .requestEntityTooLarge
        case 414: return .requestURITooLong
        case 415: return .unsupportedMediaType
        case 416: return .requestedRangeNotSatisfiable
        case 417: return .expectationFailed
        case 500: return .internalServerError
        case 501: return .notImplemented
        case 502: return .badGateway
        case 503: return .serviceUnavailable
        case 504: return .gatewayTimeout
        case 505: return .httpVersionNotSupported
         default: return .custom(code: code, message: "Unkown")
        }
    }
    
    var defaultPage: String? {
        switch self {
        case .notFound: return notFoundPage
        default: return nil
        }
    }
    
    public var description: String {
        return "\(statusCode) \(statusDescription)"
    }
}
