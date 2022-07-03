import Foundation

public class SimpleHTTPServer: HTTPServer {
  
  public var name: String
  public var host: String
  public var port: UInt16
  
  public init(name: String, host: String, port: UInt16 = 80) {
    self.name = name
    self.host = host
    self.port = port
  }
}
