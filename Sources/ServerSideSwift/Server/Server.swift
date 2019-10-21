import Dispatch
import Foundation
import OpenSSL

let keyword = "?include:"

public enum AccessControl {
  case acceptAll(blacklist: [String])
  case blockAll(whitelist: [String])
  
  func shouldAllowAccessTo(ipAddress: String) -> Bool {
    switch self {
    case .acceptAll(let blacklist): return !blacklist.contains(ipAddress)
    case .blockAll(let whitelist): return whitelist.contains(ipAddress)
    }
  }
}

typealias ServerEndpoint = (method: Method, url: String, handler: (_ request: Request, _ response: ResponseBuilder) -> Void)
typealias URLAccess = (url: String, accessControl: AccessControl, responseStatus: ResponseStatus)

public class Server {
    
  static let supportedHTTPVersions: [String] = ["http/1.1"]
  var httpUrlPrefix: String { "http://" }
  
  let accessControl: AccessControl
  public var staticFilesRoot: String?
  var port: UInt16
  var host: String
  
  private let endpoints: [ServerEndpoint]
  private let urlAccessControl: [URLAccess]
  
  public static func new(host: String, builder: (ServerBuilder) -> Void) -> [Server] {
    let serverBuilder = ServerBuilder(host: host)
    builder(serverBuilder)
    return serverBuilder.servers
  }
  
  init(host: String,
       port: UInt16,
       accessControl: AccessControl,
       staticFilesRoot: String?,
       endpoints: [ServerEndpoint],
       urlAccessControl: [URLAccess]) {
    self.host = host
    self.port = port
    self.accessControl = accessControl
    self.staticFilesRoot = staticFilesRoot
    self.endpoints = endpoints
    self.urlAccessControl = urlAccessControl
  }
  
  func getHandlerFor(method: Method, url: String) -> ((Request, ResponseBuilder) -> Void)? {
    for handler in endpoints {
      if handler.method == .any || handler.method == method {
        if let end = handler.url.firstIndex(of: "*") {
          if url.starts(with: handler.url[..<end]) {
            return handler.handler
          }
        } else if handler.url == url {
          return handler.handler
        }
      }
    }
    return nil
  }
  
  func replaceIncludes(in originalString: String, depth: Int = 0) -> String {
    guard depth < 3 else { return originalString }
    var string: String = ""
    for line in originalString.components(separatedBy: .newlines) {
      if line.trimWhitespace.starts(with: keyword) {
        if let fileString = try? String(contentsOfFile: (staticFilesRoot ?? "") + line.trimWhitespace.replacingOccurrences(of: keyword, with: "")) {
          string += replaceIncludes(in: fileString, depth: depth + 1)
        }
      }
      else { string += line + "\n"}
    }
    return string
  }
  
  func staticFileHandler(request: Request, responseBuilder: ResponseBuilder) {
    var url: String = (staticFilesRoot ?? "") + request.url
    
    if request.method == .head { responseBuilder.omitBody = true }
    var isDirectory: ObjCBool = ObjCBool(true)
    if FileManager().fileExists(atPath: url, isDirectory: &isDirectory), !isDirectory.boolValue {
      var fileExtension = ""
      let splits = url.split(separator: "/", omittingEmptySubsequences: true)
      if let fileName = splits.last {
        let fileNameSplits = fileName.split(separator: ".")
        if let potentialFileExtension = fileNameSplits.last { fileExtension = String(potentialFileExtension) }
      }
      responseBuilder.contentType = .from(fileExtension: fileExtension)
      if case .html = responseBuilder.contentType,
        case .css = responseBuilder.contentType
      { if let fileString = try? String(contentsOfFile: url) { responseBuilder.bodyString = replaceIncludes(in: fileString) } }
      else if let fileData = try? Data(contentsOf: URL(fileURLWithPath: url)) { responseBuilder.body = fileData }
    } else {
      if url.last != "/" { url += "/" }
      url += "index.html"
      if let fileString = try? String(contentsOfFile: url) {
        responseBuilder.bodyString = replaceIncludes(in: fileString)
        responseBuilder.contentType = .html
      } else {
        responseBuilder.status = .notFound
        responseBuilder.bodyString = notFoundPage
        responseBuilder.contentType = .html
      }
    }
    
    responseBuilder.lastModifiedDate = (try? FileManager.default.attributesOfItem(atPath: url))?[FileAttributeKey.modificationDate] as? Date
    responseBuilder.complete()
  }
  
  func getHTMLForStatus(for status: ResponseStatus) -> String {
    let customHTML = try? String(contentsOfFile: "\(staticFilesRoot ?? "")/\(status.statusCode).html")
    return customHTML ?? htmlPage403
  }
  
  func handleConnection(connection: ClientConnection) {
    guard accessControl.shouldAllowAccessTo(ipAddress: connection.clientAddress) else { return }
    while let request = connection.getRequest() {
      let responseBuilder = ResponseBuilder(clientConnection: connection)
      for accessControlRule in urlAccessControl where
        request.url.starts(with: accessControlRule.url) &&
        !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: connection.clientAddress) {
          responseBuilder.status = accessControlRule.responseStatus
          if request.method == .get {
            responseBuilder.bodyString = getHTMLForStatus(for: accessControlRule.responseStatus)
            responseBuilder.contentType = .html
          }
          break
      }
      guard case .ok = responseBuilder.status else {
        responseBuilder.complete()
        continue
      }
      
      if let handler = getHandlerFor(method: request.method, url: request.url) { handler(request, responseBuilder) }
      else if request.method == .get, let _ = staticFilesRoot { staticFileHandler(request: request, responseBuilder: responseBuilder) }
      else {
        responseBuilder.status = .badRequest
        responseBuilder.complete()
      }
    }
  }
  
  public func start() {
    Router.add(server: self)
  }
}
