import Foundation

import HelloCore
import HelloServer

actor CatGameServer: HTTPServer {
  
  var name: String { "Hello Test" }
  var host: String { "ambient.com" }
  
  var staticFilesRoot: URL? {
    URL(fileURLWithPath: #file)
      .deletingLastPathComponent()
      .appendingPathComponent("static")
  }
  
//  override var redirects: [HTTPRedirect] {[
//    HTTPRedirect(from: "www.ambient.com")
//  ]}
  
  var endpoints: [HTTPEndpoint] {[
    HTTPEndpoint(.get, "/test", defaultHandle)
  ]}
  
  func defaultHandle(request: HTTPRequest<Data?>) async -> HTTPResponse<Data?> {
    let responseBuilder = ResponseBuilder()
    responseBuilder.bodyString = "Hello"
    return responseBuilder.response
  }
}

actor HelloTestServer: HTTPServer {
  var name: String { "Hello Test" }
  var host: String { "ambient.com" }
  
  
}
