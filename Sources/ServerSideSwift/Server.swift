import Dispatch
import Foundation
import OpenSSL

func alpn_select_callback( _ sslSocket: UnsafeMutablePointer<SSL>?,
                           _ out: UnsafeMutablePointer<UnsafePointer<UInt8>?>?,
                           _ outlen: UnsafeMutablePointer<UInt8>?,
                           _ supportedProtocols: UnsafePointer<UInt8>?,
                           _ inlen: UInt32,
                           _ args: UnsafeMutableRawPointer?) -> Int32 {
  if let supportedProtocols = supportedProtocols {
    var data = [UInt8]()
    for i in 0..<inlen {
      data.append(supportedProtocols.advanced(by: Int(i)).pointee)
    }
    if let string = String(bytes: data, encoding: .utf8) {
      for httpVersion in Server.supportedHTTPVersions {
        if let match = string.range(of: httpVersion) {
          let offset = string.distance(from: string.startIndex, to: match.lowerBound)
          out?.initialize(to: supportedProtocols.advanced(by: offset))
          outlen?.initialize(to: UInt8(httpVersion.count))
          return SSL_TLSEXT_ERR_OK
        }
      }
      return SSL_TLSEXT_ERR_ALERT_FATAL
    }
  }
  return SSL_TLSEXT_ERR_NOACK
}

public struct SSLFiles {
  let certificate: String
  let privateKey: String
  
  public init(certificate: String, privateKey: String) {
    self.certificate = certificate
    self.privateKey = privateKey
  }
}

public class Server {
    
  static let supportedHTTPVersions: [String] = ["http/1.1"]
  
  public enum AccessControl {
    case acceptAll(blacklist: [String])
    case blockAll(whitelist: [String])
    
    func shouldAllowAccessTo(ipAddress: String) -> Bool {
      switch self {
      case .acceptAll(let blacklist): return !blacklist.contains(ipAddress)
      case .blockAll(let whitelist): return whitelist.contains(ipAddress)
      }
    }
  }

  private func hostRedirectServer(from host: String, withSSL sslFiles: SSLFiles?) -> Server {
    let redirectServer = Server(host: host)
    redirectServer.shouldProvideStaticFiles = false
    redirectServer.addEndpoint(method: .any, url: "*", handler: { request, responseBuilder in
      responseBuilder.status = .movedPermanently
      responseBuilder.location = "http\(sslFiles != nil ? "s" : "")://" + self.host + request.url
      responseBuilder.complete()
    })
    if let sslFiles = sslFiles { redirectServer.useTLS(sslFiles: sslFiles) }
    
    return redirectServer
  }
  
  private func httpToHttpsRedirectServer() -> Server {
    let redirectServer = Server(host: host)
    redirectServer.shouldProvideStaticFiles = false
    redirectServer.addEndpoint(method: .any, url: "*", handler: {request, responseBuilder in
      responseBuilder.status = .movedPermanently
      responseBuilder.location = "https://" + self.host + request.url
      responseBuilder.complete()
    })
    
    return redirectServer
  }

  public var httpsPort: UInt16 = Socket.defaultHTTPSPort
  public var httpPortDebug: UInt16 = 8018
  public var staticDocumentRoot: String = /*CommandLine.arguments[0] +*/ "./static"
  public var accessControl: AccessControl = .acceptAll(blacklist: [])
  public var shouldProvideStaticFiles: Bool = true
  #if DEBUG
  public var httpPort: UInt16 { get { httpPortDebug } set {} }
  public var shouldRedirectHttpToHttps: Bool { get { true } set {} }
  public var ignoreRequestHostChecking: Bool { get { true } set {} }
  private var host: String { get { "localhost:\(httpPortDebug)" } set {} }
  private var hostRedirects: [(host: String, sllFiles: SSLFiles?)] { get { [] } set {} }
  #else
  public var httpPort: UInt16 = Socket.defaultHTTPPort
  public var ignoreRequestHostChecking: Bool = false
  public var shouldRedirectHttpToHttps: Bool = false
  private var host: String
  private var hostRedirects: [(host: String, sllFiles: SSLFiles?)] = []
  #endif
  
  private var usingTLS: Bool = false
  private var endpoints: [(method: Method, url: String, handler: (_ request: Request, _ response: ResponseBuilder) -> Void)] = []
  private var urlAccessControl: [(url: String, accessControl: AccessControl, responseStatus: ResponseStatus)] = []
  
  public var sslContext: UnsafeMutablePointer<SSL_CTX>!
  
  private func initSSLContext(sslFiles: SSLFiles) {
    SSL_load_error_strings();
    SSL_library_init();
    OpenSSL_add_all_digests()
    sslContext = SSL_CTX_new(SSLv23_method())
    SSL_CTX_set_alpn_select_cb(sslContext, alpn_select_callback, nil)
    if SSL_CTX_use_certificate_file(sslContext, sslFiles.certificate , SSL_FILETYPE_PEM) != 1 {
      fatalError("Failed to use provided certificate file")
    }
    if SSL_CTX_use_PrivateKey_file(sslContext, sslFiles.privateKey, SSL_FILETYPE_PEM) != 1 {
      fatalError("Failed to use provided preivate key file")
    }
  }
  
  public init(host: String) {
    self.host = host
  }
  
  public func useTLS(sslFiles: SSLFiles) {
    #if !(DEBUG)
    initSSLContext(sslFiles: sslFiles)
    usingTLS = true
    #endif
  }

  public func addHostRedirect(from host: String, withSSL sllFiles: SSLFiles? = nil) {
    hostRedirects.append((host: host, sllFiles: sllFiles))
  }
  
  public func addEndpoint(method: Method, url: String, handler: @escaping (Request, ResponseBuilder) -> Void) {
    endpoints.append((method: method,
                      url: url,
                      handler: handler))
  }
  
  public func addUrlSpecificAccessControl(subDirectory: String, accessControl: AccessControl, responseStatus: ResponseStatus) {
    urlAccessControl.append((url: subDirectory,
                             accessControl: accessControl,
                             responseStatus: responseStatus))
  }
  
  func getHandlerFor(method: Method, url: String) -> ((Request, ResponseBuilder) -> Void)? {
    for handler in endpoints {
      if handler.method == .any || handler.method == method {
        if let end = handler.url.firstIndex(of: "*") {
          if url.starts(with: handler.url[..<end]) {
            return handler.handler
          }
        } else if handler.url == url {
          return handler.handler
        }
      }
    }
    return nil
  }
  
  func staticFileHandler(request: Request, responseBuilder: ResponseBuilder) {
    var url: String = staticDocumentRoot + request.url
    
    if request.method == .head { responseBuilder.omitBody = true }
    
    if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
      var fileExtension = ""
      let splits = url.split(separator: "/", omittingEmptySubsequences: true)
      if let fileName = splits.last {
        let fileNameSplits = fileName.split(separator: ".")
        if let potentialFileExtension = fileNameSplits.last { fileExtension = String(potentialFileExtension) }
      }
      responseBuilder.body = file
      responseBuilder.contentType = .from(fileExtension: fileExtension)
    } else {
      guard url.last == "/" else {
        url += "/"
        responseBuilder.location = "http\(usingTLS ? "s" : "")://" + host + request.url + "/"
        responseBuilder.status = .movedPermanently
        responseBuilder.complete()
        return
      }
      url += "index.html"
      if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
        responseBuilder.body = file
        responseBuilder.contentType = .html
      } else {
        responseBuilder.status = .notFound
        responseBuilder.bodyString = notFoundPage
        responseBuilder.contentType = .html
      }
    }
    
    responseBuilder.lastModifiedDate = (try? FileManager.default.attributesOfItem(atPath: url))?[FileAttributeKey.modificationDate] as? Date
    responseBuilder.complete()
  }
  
  func handleConnection(socket: ClientSocket) {
    if let socket = socket as? ClientSSLSocket { socket.initSSLConnection(sslContext: sslContext) }
    guard accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) else { return }
    while let request = socket.acceptRequest() {
      let responseBuilder = ResponseBuilder(clientSocket: socket)
      for accessControlRule in urlAccessControl where
        request.url.starts(with: accessControlRule.url) &&
        !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) {
          responseBuilder.status = accessControlRule.responseStatus
          continue
      }
      guard case .ok = responseBuilder.status else {
        responseBuilder.complete()
        continue
      }
      
      if let handler = getHandlerFor(method: request.method, url: request.url) { handler(request, responseBuilder) }
      else { staticFileHandler(request: request, responseBuilder: responseBuilder) }
    }
  }
  
  public func start() {
    if usingTLS && shouldRedirectHttpToHttps {
      Router.addServer(host: host,
                       port: httpPort,
                       usingTLS: false,
                       server: httpToHttpsRedirectServer())
    }
  
    for hostRedirect in hostRedirects {
      if !usingTLS || shouldRedirectHttpToHttps {
        Router.addServer(host: hostRedirect.host,
                         port: httpPort,
                         usingTLS: false,
                         server: hostRedirectServer(from: hostRedirect.host, withSSL: nil))
      }
      if let sllFiles = hostRedirect.sllFiles, usingTLS {
        Router.addServer(host: hostRedirect.host,
                         port: httpsPort,
                         usingTLS: true,
                         server: hostRedirectServer(from: hostRedirect.host, withSSL: sllFiles))
      }
    }
    
    Router.addServer(host: host,
                     port: usingTLS ? httpsPort : httpPort,
                     usingTLS: usingTLS,
                     server: self)
  }
}
