import Foundation

public protocol HTTPServer: Server {
  var staticFilesRoot: URL? { get }
  var endpoints: [HTTPEndpoint] { get }
  
  func handle(request: HTTPRequest) async throws -> HTTPResponse
}

public extension HTTPServer {
  var port: UInt16 { 80 }
  var staticFilesRoot: URL? { nil }
  var endpoints: [HTTPEndpoint] { [] }
  
  func getHandlerFor(method: HTTPMethod, url: String) -> ((HTTPRequest) async -> HTTPResponse)? {
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
  
  func staticFileHandler(request: HTTPRequest) throws -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    guard let staticFilesRoot else { throw HTTPError(ccde: .notFound) }
    var url: URL = staticFilesRoot.appendingPathComponent(request.url)
    
    if request.method == .head { responseBuilder.omitBody = true }
    var isDirectory: ObjCBool = ObjCBool(true)
    if FileManager().fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
      if let fileExtension = url.fileExtension {
        responseBuilder.contentType = .from(fileExtension: fileExtension)
      }
      //      if responseBuilder.contentType == .html || responseBuilder.contentType == .css {
      //        let currentDirectory = String(url[...(url.lastIndex(of: "/") ?? url.endIndex)])
      //        if let fileString = try? String(contentsOfFile: url) {
      //          responseBuilder.bodyString = Page.replaceIncludes(in: fileString,
      //                                                            from: currentDirectory,
      //                                                            staticRoot: staticFilesRoot)
      //        }
      //      }
      else if let fileData = try? Data(contentsOf: url) { responseBuilder.body = fileData }
    } else {
      url.appendPathComponent("index.html")
//      print(url)
      if let fileString = try? String(contentsOf: url) {
        responseBuilder.bodyString = fileString//Page.replaceIncludes(in: fileString,
        //         from: url.replacingOccurrences(of: "index.html", with: ""),
        //       staticRoot: staticFilesRoot)
        responseBuilder.contentType = .html
      } else {
        responseBuilder.status = .notFound
        responseBuilder.bodyString = notFoundPage
        responseBuilder.contentType = .html
      }
    }
    
    responseBuilder.lastModifiedDate = (try? FileManager.default.attributesOfItem(atPath: url.path))?[FileAttributeKey.modificationDate] as? Date
    return responseBuilder.response
  }
  
  func handle(request: HTTPRequest) async throws -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    for accessControlRule in urlAccessControl where
    request.url.starts(with: accessControlRule.url) &&
    !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: request.clientAddress) {
      responseBuilder.status = accessControlRule.responseStatus
      if request.method == .get {
        responseBuilder.bodyString = getHTMLForStatus(for: accessControlRule.responseStatus)
        responseBuilder.contentType = .html
      }
      break
    }
    guard case .ok = responseBuilder.status else {
      return responseBuilder.response
    }
    
    if let handler = getHandlerFor(method: request.method, url: request.url) {
      return await handler(request)
    } else if [.get, .head].contains(request.method) && staticFilesRoot != nil {
      return try staticFileHandler(request: request)
    } else {
      responseBuilder.status = .badRequest
      return responseBuilder.response
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
    guard accessControl.shouldAllowAccessTo(ipAddress: connection.clientAddress) else { return }
    for try await request in connection.httpRequests {
      do {
        connection.send(response: try await handle(request: request))
      } catch {
        connection.send(response: .serverError)
      }
    }
  }
}
