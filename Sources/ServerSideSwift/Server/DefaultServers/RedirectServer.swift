import Foundation

public class HTTPSRedirectServer: HTTPSServer {
  
  public var sslContext: OpaquePointer!
  public var sslFiles: SSLFiles
  
  public var name: String { "\(host) Redirect" }
  public var host: String
  
  init(host: String, sslFiles: SSLFiles) {
    self.host = host
    self.sslFiles = sslFiles
  }
  
  public func handle(request: HTTPRequest) async throws -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    responseBuilder.status = .movedPermanently
    responseBuilder.location = "https://" + self.host + request.url
    return responseBuilder.response
  }
}

public class HTTPRedirectServer: HTTPServer {
  
  public var name: String { "\(host) Redirect" }
  public var host: String
  
  init(host: String) {
    self.host = host
  }
  
  public func handle(request: HTTPRequest) async throws -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    responseBuilder.status = .movedPermanently
    responseBuilder.location = "https://" + self.host + request.url
    return responseBuilder.response
  }
}

public extension HTTPServer {
  func redirectServer(from host: String, with sslFiles: SSLFiles) -> some HTTPSServer {
    HTTPSRedirectServer(host: host, sslFiles: sslFiles)
  }
  
  func redirectServer(from host: String) -> some HTTPServer {
    HTTPRedirectServer(host: host)
  }
  
  func wwwRedirectServer() -> some HTTPServer {
    HTTPRedirectServer(host: "www.\(host)")
  }
  
  func wwwRedirectServer(with sslFiles: SSLFiles) -> some HTTPSServer {
    HTTPSRedirectServer(host: "www.\(host)", sslFiles: sslFiles)
  }
}
