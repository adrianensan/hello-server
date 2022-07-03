import ServerSideSwift
import Foundation

class CatGameServer: HTTPServer {
  
  var name: String { "Cat Game" }
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
  
  func defaultHandle(request: HTTPRequest) async -> HTTPResponse {
    let responseBuilder = ResponseBuilder()
    responseBuilder.bodyString = "Hello"
    return responseBuilder.response
  }
}

class HelloTestServer: HTTPServer {
  var name: String { "Hello Test" }
  var host: String { "ambient.com" }
  
  
}
