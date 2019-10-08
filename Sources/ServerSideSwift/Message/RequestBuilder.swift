import Foundation

public class RequestBuilder: Message {
  
  public var method: Method = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  weak private var socket: OutgoingSocket?
  
  public var request: Request { Request(requestBuilder: self) }
  
  override init() { super.init() }
  
  public init(to socket: OutgoingSocket) {
    self.socket = socket
    super.init()
  }
  
  public func send(responseHandler: (Response) -> Void) {
    guard let socket = socket else {
      print("Attempted to complete a request after it was already sent, don't do this, nothing happens")
      return
    }
    if host == nil { host = socket.host }
    socket.sendRequest(request)
    if let response = socket.getResponse() { responseHandler(response) }
    else { print("error") }
    self.socket = nil
  }
}

extension RequestBuilder: CustomStringConvertible { public var description: String { request.description } }
