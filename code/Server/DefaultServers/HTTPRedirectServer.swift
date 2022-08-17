import Foundation

import HelloCore

public actor HTTPToHTTPSRedirectServer: HTTPServer {
  
  public var name: String { "\(host) Redirect" }
  public var host: String
  
  init(host: String) {
    self.host = host
  }
  
  public func handle(request: RawHTTPRequest) async throws -> HTTPResponse<Data?> {
    .init(status: .movedPermanently, customeHeaders: ["Location: https://\(self.host + request.url)"])
  }
}

public extension HTTPSServer {
  var httpToHttpsRedirectServer: HTTPServer {
    HTTPToHTTPSRedirectServer(host: host)
  }
}
