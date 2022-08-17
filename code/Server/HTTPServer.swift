import Foundation

import HelloCore

public protocol HTTPServer: TCPServer {
  var staticFilesRoot: URL? { get }
  var endpoints: [HTTPEndpoint] { get }
  func preCondition(_ request: HTTPRequest<Data?>) async throws -> HTTPResponse<Data?>?
}

public extension HTTPServer {
  var port: UInt16 { 80 }
  var type: SocketType { .tcp }
  var staticFilesRoot: URL? { nil }
  var endpoints: [HTTPEndpoint] { [] }
  
  func preCondition(_ request: HTTPRequest<Data?>) async throws -> HTTPResponse<Data?>? {
    return nil
  }
  
  func getHandlerFor(method: HTTPMethod, url: String) -> ((HTTPRequest<Data?>) async throws -> HTTPResponse<Data?>)? {
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
  
  func staticFileHandler(request: HTTPRequest<Data?>) throws -> HTTPResponse<Data?> {
    let responseBuilder = ResponseBuilder()
    guard let staticFilesRoot else { throw HTTPError(ccde: .notFound) }
    var url: URL = staticFilesRoot.appendingPathComponent(request.url)
    
    var isDirectory: ObjCBool = ObjCBool(true)
    guard FileManager().fileExists(atPath: url.path, isDirectory: &isDirectory) else { return .notFound }
    if isDirectory.boolValue {
      //      if responseBuilder.contentType == .html || responseBuilder.contentType == .css {
      //        let currentDirectory = String(url[...(url.lastIndex(of: "/") ?? url.endIndex)])
      //        if let fileString = try? String(contentsOfFile: url) {
      //          responseBuilder.bodyString = Page.replaceIncludes(in: fileString,
      //                                                            from: currentDirectory,
      //                                                            staticRoot: staticFilesRoot)
      //        }
      //      }
      url.appendPathComponent("index.html")
    }
    
    if let fileString = try? Data(contentsOf: url) {
      var contentType: ContentType?
      if let fileExtension = url.fileExtension {
        contentType = .from(fileExtension: fileExtension)
      }
      let lastModificationDate = (try? FileManager.default.attributesOfItem(atPath: url.path))?[FileAttributeKey.modificationDate] as? Date
      return .init(status: .ok, contentType: contentType, lastModifiedDate: lastModificationDate, body: fileString, omitBody: request.method == .head)
      //Page.replaceIncludes(in: fileString,
      //         from: url.replacingOccurrences(of: "index.html", with: ""),
      //       staticRoot: staticFilesRoot)
    } else {
      return .notFound
    }
  }
  
  func handle(request: HTTPRequest<Data?>) async throws -> HTTPResponse<Data?> {
    for accessControlRule in urlAccessControl {
      if request.url.starts(with: accessControlRule.url) && !accessControlRule.accessControl.shouldAllowAccessTo(address: request.clientAddress) {
        return .init(status: accessControlRule.responseStatus)
      }
    }
    
    if let handler = getHandlerFor(method: request.method, url: request.url) {
      if let response = try await preCondition(request) {
        return response
      }
      return try await handler(request)
    } else if [.get, .head].contains(request.method) && staticFilesRoot != nil {
      return try staticFileHandler(request: request)
    } else {
      return .badRequest
    }
  }
  
  func getHTMLForStatus(for status: HTTPResponseStatus) -> String {
    guard let staticFilesRoot,
          let customHTML = try? String(contentsOf: staticFilesRoot.appendingPathComponent("\(status.statusCode).html")) else {
      return htmlPage403
    }
    return customHTML
  }
  
  func handleConnection(connection: ClientConnection) async throws {
    guard accessControl.shouldAllowAccessTo(address: connection.clientAddress) else { return }
    for try await request in connection.httpRequests {
      Log.verbose("Request from \(connection.clientAddress), \(request.url)", context: "HTTP")
      do {
        try await connection.send(response: try await handle(request: request))
      } catch {
        Log.error("Server error: \(error)", context: "Server")
        try await connection.send(response: .serverError)
      }
    }
  }
}
