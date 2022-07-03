import Foundation

public class HTTPToHTTPSRedirectServer: HTTPServer {
  
  public var name: String
  public var host: String
  
  init(name: String, host: String) {
    self.name = name
    self.host = host
  }
  
  public func handle(request: HTTPRequest) async throws -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    responseBuilder.status = .movedPermanently
    responseBuilder.location = "https://" + self.host + request.url
    return responseBuilder.response
  }
}

extension HTTPSServer {
  var httpToHttpsRedirectServer: HTTPServer {
    HTTPToHTTPSRedirectServer(name: name, host: host)
  }
}
