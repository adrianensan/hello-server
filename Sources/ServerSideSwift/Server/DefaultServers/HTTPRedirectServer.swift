import Foundation

public class HTTPToHTTPSRedirectServer: HTTPServer {
  
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

public extension HTTPSServer {
  var httpToHttpsRedirectServer: HTTPServer {
    HTTPToHTTPSRedirectServer(host: host)
  }
}
