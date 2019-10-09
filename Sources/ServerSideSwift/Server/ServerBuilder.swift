import Foundation

public struct SSLFiles {
  let certificate: String
  let privateKey: String
  
  public init(certificate: String, privateKey: String) {
    self.certificate = certificate
    self.privateKey = privateKey
  }
}

public class ServerBuilder {
  #if DEBUG
  var host: String { get { "localhost:\(port ??  Socket.defaultDebugPort)" } set {} }
  public var port: UInt16? { get { debugPort ?? Socket.defaultDebugPort } set {} }
  public var sslFiles: SSLFiles? { get { nil } set {} }
  public var ignoreRequestHostChecking: Bool { get { true } set {} }
  public var debugStaticFilesRoot: String?
  #else
  var host: String
  public var port: UInt16?
  public var sslFiles: SSLFiles?
  public var ignoreRequestHostChecking: Bool = false
  public var debugStaticFilesRoot: String? { get { nil } set {} }
  #endif
  public var staticFilesRoot: String?
  public var debugPort: UInt16?
  
  var endpoints: [(method: Method, url: String, handler: (_ request: Request, _ response: ResponseBuilder) -> Void)] = []
  var urlAccessControl: [(url: String, accessControl: AccessControl, responseStatus: ResponseStatus)] = []
  var hostRedirects: [(host: String, sllFiles: SSLFiles?)] = []
  
  
  public init(host: String) {
    self.host = host
  }
  
  public func addHostRedirect(from host: String, withSSL sllFiles: SSLFiles? = nil) {
    #if !(DEBUG)
    hostRedirects.append((host: host, sllFiles: sllFiles))
    #endif
  }
  
  public func addEndpoint(method: Method, url: String, handler: @escaping (Request, ResponseBuilder) -> Void) {
    endpoints.append((method: method,
                      url: url,
                      handler: handler))
  }
  
  public func addUrlSpecificAccessControl(subDirectory: String, accessControl: AccessControl, responseStatus: ResponseStatus) {
    #if !(DEBUG)
    urlAccessControl.append((url: subDirectory,
                             accessControl: accessControl,
                             responseStatus: responseStatus))
    #endif
  }
  
  public var servers: [Server] {
    var servers: [Server]  = []
    if let sslFiles = sslFiles {
      servers.append(SSLServer(host: host,
                               port: port ?? Socket.defaultHTTPSPort,
                               staticFilesRoot: debugStaticFilesRoot ?? self.staticFilesRoot,
                               endpoints: endpoints,
                               urlAccessControl: urlAccessControl,
                               sslFiles: sslFiles))
      servers.append(httpToHttpsRedirectServer())
      for hostRedirect in hostRedirects {
        servers.append(hostRedirectServer(from: hostRedirect.host, withSSL: hostRedirect.sllFiles))
      }
    }
    else {
      servers.append(Server(host: host,
                            port: port ?? Socket.defaultHTTPPort,
                            staticFilesRoot: debugStaticFilesRoot ?? self.staticFilesRoot,
                            endpoints: endpoints,
                            urlAccessControl: urlAccessControl))
    }
    
    for hostRedirect in hostRedirects {
      servers.append(hostRedirectServer(from: hostRedirect.host, withSSL: nil))
    }
    
    return servers
  }
  
  private func hostRedirectServer(from host: String, withSSL sslFiles: SSLFiles?) -> Server {
    return Server.new(host: host) {
      $0.sslFiles = sslFiles
      $0.addEndpoint(method: .any, url: "*", handler: { request, responseBuilder in
        responseBuilder.status = .movedPermanently
        responseBuilder.location = "http\(sslFiles != nil ? "s" : "")://" + self.host + request.url
        responseBuilder.complete()
      })
    }[0]
  }
  
  private func httpToHttpsRedirectServer() -> Server {
    return Server.new(host: host) {
      $0.addEndpoint(method: .any, url: "*", handler: {request, responseBuilder in
        responseBuilder.status = .movedPermanently
        responseBuilder.location = "https://" + self.host + request.url
        responseBuilder.complete()
      })
    }[0]
  }
}

//extension ServerBuilder: CustomStringConvertible { public var description: String { server.description } }
