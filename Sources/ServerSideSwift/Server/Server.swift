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

typealias ServerEndpoint = (method: Method, url: String, handler: (_ server: Server, _ request: Request, _ response: ResponseBuilder) -> Void)
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
  
  func getHandlerFor(method: Method, url: String) -> ((Server, Request, ResponseBuilder) -> Void)? {
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
  
  func staticFileHandler(request: Request, responseBuilder: ResponseBuilder) {
    print(request.description)
    var url: String = (staticFilesRoot ?? "") + request.url
    
    if request.method == .head { responseBuilder.omitBody = true }
    var isDirectory: ObjCBool = ObjCBool(true)
    if FileManager().fileExists(atPath: url, isDirectory: &isDirectory), !isDirectory.boolValue {
      if let fileExtension = url.fileExtension { responseBuilder.contentType = .from(fileExtension: fileExtension) }
      if case .html = responseBuilder.contentType,
        case .css = responseBuilder.contentType
      {
        let currentDirectory = String(url[...(url.lastIndex(of: "/") ?? url.endIndex)])
        if let fileString = try? String(contentsOfFile: url) { responseBuilder.bodyString = Page.replaceIncludes(in: fileString,
                                                                                                                 from: currentDirectory,
                                                                                                                 staticRoot: staticFilesRoot) }
        
      }
      else if let fileData = try? Data(contentsOf: URL(fileURLWithPath: url)) { responseBuilder.body = fileData }
    } else {
      guard url.last == "/" else {
        responseBuilder.status = .temporaryRedirect
        responseBuilder.location = request.url + "/"
        responseBuilder.complete()
        return
      }
      url += "index.html"
      if let fileString = try? String(contentsOfFile: url) {
        responseBuilder.bodyString = Page.replaceIncludes(in: fileString,
                                                          from: url.replacingOccurrences(of: "index.html", with: ""),
                                                          staticRoot: staticFilesRoot)
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
      
      if let handler = getHandlerFor(method: request.method, url: request.url) { handler(self, request, responseBuilder) }
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
