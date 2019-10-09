import Dispatch
import Foundation
import OpenSSL

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
  
  var accessControl: AccessControl = .acceptAll(blacklist: [])
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
       staticFilesRoot: String?,
       endpoints: [ServerEndpoint],
       urlAccessControl: [URLAccess]) {
    self.host = host
    self.port = port
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
  
  func staticFileHandler(request: Request, responseBuilder: ResponseBuilder) {
    var url: String = (staticFilesRoot ?? "") + request.url
    
    if request.method == .head { responseBuilder.omitBody = true }
    
    if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
      var fileExtension = ""
      let splits = url.split(separator: "/", omittingEmptySubsequences: true)
      if let fileName = splits.last {
        let fileNameSplits = fileName.split(separator: ".")
        if let potentialFileExtension = fileNameSplits.last { fileExtension = String(potentialFileExtension) }
      }
      responseBuilder.body = file
      responseBuilder.contentType = .from(fileExtension: fileExtension)
    } else {
      guard url.last == "/" else {
        responseBuilder.location = httpUrlPrefix + host + request.url + "/"
        responseBuilder.status = .movedPermanently
        responseBuilder.complete()
        return
      }
      url += "index.html"
      if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
        responseBuilder.body = file
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
  
  func handleConnection(socket: ClientSocket) {
    guard accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) else { return }
    while let request = socket.acceptRequest() {
      let responseBuilder = ResponseBuilder(clientSocket: socket)
      for accessControlRule in urlAccessControl where
        request.url.starts(with: accessControlRule.url) &&
        !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) {
          responseBuilder.status = accessControlRule.responseStatus
          continue
      }
      guard case .ok = responseBuilder.status else {
        responseBuilder.complete()
        continue
      }
      
      if let handler = getHandlerFor(method: request.method, url: request.url) { handler(request, responseBuilder) }
      else if let _ = staticFilesRoot { staticFileHandler(request: request, responseBuilder: responseBuilder) }
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
