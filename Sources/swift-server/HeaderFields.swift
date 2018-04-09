import Foundation

let serverHeader = "Server: adrian-ensan-server"
let locationHeader = "Location: "

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

enum ContentType {
    case none
    case plain
    case html
    case css
    case js
    case otf
    case ttf
    case woff
    case woff2
    case png
    case jpg
    case jpeg
    case tif
    case tiff
    case gif
    case svg
    case ico
    case json
    case xml
    case pdf
    case doc
    case docx
    case other
    case custom(type: String)
    
    static let baseString = "Content-Type: "
    
    var typeString: String {
        switch self {
        case       .none: return ""
        case      .plain: return "text/plain"
        case       .html: return "text/html"
        case        .css: return "text/css"
        case         .js: return "text/javascript"
        case        .otf: return "font/otf"
        case        .ttf: return "font/ttf"
        case       .woff: return "font/woff"
        case      .woff2: return "font/woff2"
        case        .png: return "image/png"
        case .jpg, .jpeg: return "image/jpeg"
        case .tif, .tiff: return "image/tiff"
        case        .gif: return "image/gif"
        case        .svg: return "image/svg+xml"
        case        .ico: return "image/x-icon"
        case       .json: return "application/json"
        case        .xml: return "application/xml"
        case        .pdf: return "application/pdf"
        case        .doc: return "application/msword"
        case       .other: return "application/octet-stream"
        case       .docx: return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case .custom(let s): return s
        }
    }
    
    var string: String {
        return ContentType.baseString + typeString
    }
}

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
