import Foundation

public struct SSLFiles {
  let certificate: String
  let privateKey: String
  
  public init(certificate: String, privateKey: String) {
    self.certificate = certificate
    self.privateKey = privateKey
  }
}

//public protocol Server: AnyObject {
//  var name: String { get }
//  var host: String { get }
//  var sslFiles: SSLFiles? { get }
//  var port: UInt16 { get }
//  var accessControl: AccessControl { get }
//  var staticRoot: String? { get }
//  var endpoints: [HTTPEndpoint] { get }
//}
//
//public extension Server {
//  var sslFiles: SSLFiles? { nil }
//  var port: UInt16 { sslFiles == nil ? 80 : 443 }
//  var accessControl: AccessControl { .acceptAll(blacklist: []) }
//  var staticRoot: String? { "static" }
//  
//  public func start() {
//    Router.add(server: self)
//  }
//}

//public class ServerBuilder {
//  var name: String = ""
//  #if DEBUG
//  var host: String { get { "localhost" } set {} }
//  public var port: UInt16? { get { debugPort ?? Socket.getDebugPort() } set {} }
//  public var debugPort: UInt16?
//  public var sslFiles: SSLFiles? { get { nil } set {} }
//  public var ignoreRequestHostChecking: Bool { get { true } set {} }
//  public var accessControl: AccessControl { get { .acceptAll(blocklist: []) } set {} }
//  #else
//  var host: String
//  public var port: UInt16?
//  public var sslFiles: SSLFiles?
//  public var ignoreRequestHostChecking: Bool = false
//  public var accessControl: AccessControl = .acceptAll(blacklist: [])
//  #endif
//  public var staticFilesRoot: String?
//  
//  var endpoints: [ServerEndpoint] = []
//  var urlAccessControl: [(url: String, accessControl: AccessControl, responseStatus: HTTPResponseStatus)] = []
//  var hostRedirects: [(host: String, sllFiles: SSLFiles?)] = []
//  
//  
//  public init(name: String, host: String) {
//    self.name = name
//    self.host = host
//  }
//  
//  public func addHostRedirect(from redirectedHost: String, withSSL sllFiles: SSLFiles? = nil) {
//    #if !(DEBUG)
//    hostRedirects.append((host: redirectedHost, sllFiles: sllFiles))
//    #endif
//  }
//  
//  public func addEndpoint(method: HTTPMethod, url: String, handler: @escaping (HTTPRequest) async -> HTTPResponse) {
//    endpoints.append((method: method,
//                      url: url,
//                      handler: handler))
//  }
//  
//  public func addUrlSpecificAccessControl(subDirectory: String, accessControl: AccessControl, responseStatus: HTTPResponseStatus) {
//    #if !(DEBUG)
//    urlAccessControl.append((url: subDirectory,
//                             accessControl: accessControl,
//                             responseStatus: responseStatus))
//    #endif
//  }
//  
//  public var servers: [Server] {
//    var servers: [Server]  = []
//    if let sslFiles = sslFiles {
//      servers.append(SSLServer(name: name,
//                               host: host,
//                               port: port ?? Socket.defaultHTTPSPort,
//                               accessControl: accessControl,
//                               staticFilesRoot: staticFilesRoot,
//                               endpoints: endpoints,
//                               urlAccessControl: urlAccessControl,
//                               sslFiles: sslFiles))
//      servers.append(httpToHttpsRedirectServer())
//      
//      for hostRedirect in hostRedirects {
//        servers.append(hostRedirectServer(from: hostRedirect.host, withSSL: hostRedirect.sllFiles))
//      }
//    }
//    else {
//      servers.append(Server(name: name,
//                            host: host,
//                            port: port ?? Socket.defaultHTTPPort,
//                            accessControl: accessControl,
//                            staticFilesRoot: staticFilesRoot,
//                            endpoints: endpoints,
//                            urlAccessControl: urlAccessControl))
//    }
//    
//    for hostRedirect in hostRedirects {
//      servers.append(hostRedirectServer(from: hostRedirect.host, withSSL: nil))
//    }
//    
//    return servers
//  }
//  
//  private func hostRedirectServer(from redirectedHost: String, withSSL redirectedSSLFiles: SSLFiles?) -> Server {
//    let hostRedirectTo = self.host
//    let hostRedirectSSL = self.sslFiles
//    return Server.new(host: redirectedHost) {
//      $0.sslFiles = redirectedSSLFiles
//      $0.addEndpoint(method: .any, url: "*", handler: { (self, request) in
//        let responseBuilder = ResponseBuilder()
//        responseBuilder.status = .movedPermanently
//        responseBuilder.location = "http\(hostRedirectSSL != nil ? "s" : "")://" + hostRedirectTo + request.url
//        return responseBuilder
//      })
//    }[0]
//  }
//  
//  private func httpToHttpsRedirectServer() -> Server {
//    Server.new(host: host) {
//      $0.addEndpoint(method: .any, url: "*", handler: { (self, request) in
//        let responseBuilder = ResponseBuilder()
//        responseBuilder.status = .movedPermanently
//        responseBuilder.location = "https://" + self.host + request.url
//        return responseBuilder
//      })
//    }[0]
//  }
//}

//extension ServerBuilder: CustomStringConvertible { public var description: String { server.description } }
