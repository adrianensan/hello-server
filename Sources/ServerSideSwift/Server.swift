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
    redirectServer.addEndpoint(method: .any, url: "*", handler: { request, response in
      response.status = .movedPermanently
      response.location = "http\(sslFiles != nil ? "s" : "")://" + self.host + request.url
      response.complete()
    })
    if let sslFiles = sslFiles { redirectServer.useTLS(sslFiles: sslFiles) }
    
    return redirectServer
  }
  
  private func httpToHttpsRedirectServer() -> Server {
    let redirectServer = Server(host: host)
    redirectServer.shouldProvideStaticFiles = false
    redirectServer.addEndpoint(method: .any, url: "*", handler: {request, response in
      response.status = .movedPermanently
      response.location = "https://" + self.host + request.url
      response.complete()
    })
    
    return redirectServer
  }

  public var httpsPort: UInt16 = 443
  public var httpPortDebug: UInt16 = 8018
  public var staticDocumentRoot: String = /*CommandLine.arguments[0] +*/ "./static"
  public var accessControl: AccessControl = .acceptAll(blacklist: [])
  public var shouldProvideStaticFiles: Bool = true
  #if DEBUG
  public var httpPort: UInt16 { get { return httpPortDebug } set {} }
  public var shouldRedirectHttpToHttps: Bool { get { return true } set {} }
  public var ignoreRequestHostChecking: Bool { get { return true } set {} }
  private var hostRedirects: [(host: String, sllFiles: SSLFiles?)] { get { return [] } set {} }
  #else
  public var httpPort: UInt16 = 80
  public var ignoreRequestHostChecking: Bool = false
  public var shouldRedirectHttpToHttps: Bool = false
  private var hostRedirects: [(host: String, sllFiles: SSLFiles?)] = []
  #endif
  
  private var host: String
  private var usingTLS = false
  private var endpoints = [(method: Method, url: String, handler: (request: Request, response: Response) -> Void)]()
  private var urlAccessControl: [(url: String, accessControl: AccessControl, responseStatus: ResponseStatus)] = []
  
  private var sslContext: UnsafeMutablePointer<SSL_CTX>!
  
  private func initSSLContext(sslFiles: SSLFiles) {
    SSL_load_error_strings();
    SSL_library_init();
    OpenSSL_add_all_digests();
    sslContext = SSL_CTX_new(TLSv1_2_server_method())
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
    initSSLContext(sslFiles)
    usingTLS = true
    #endif
  }

  public func addHostRedirect(from host: String, withSSL sllFiles: SSLFiles? = nil) {
    hostRedirects.append((host: host, sllFiles: sllFiles))
  }
  
  public func addEndpoint(method: Method, url: String, handler: @escaping (Request, Response) -> Void) {
    endpoints.append((method: method,
                      url: url,
                      handler: handler))
  }
  
  public func addUrlSpecificAccessControl(subDirectory: String, accessControl: AccessControl, responseStatus: ResponseStatus) {
    urlAccessControl.append((url: subDirectory,
                             accessControl: accessControl,
                             responseStatus: responseStatus))
  }
  
  func getHandlerFor(method: Method, url: String) -> ((Request, Response) -> Void)? {
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
  
  func staticFileHandler(request: Request, response: Response) {
    var url: String = staticDocumentRoot + request.url
    
    if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
      var fileExtension = ""
      let splits = url.split(separator: "/", omittingEmptySubsequences: true)
      if let fileName = splits.last {
        let fileNameSplits = fileName.split(separator: ".")
        if let potentialFileExtension = fileNameSplits.last { fileExtension = String(potentialFileExtension) }
      }
      response.body = file
      response.contentType = .from(fileExtension: fileExtension)
    } else {
      guard url.last == "/" else {
        url += "/"
        response.location = "http\(usingTLS ? "s" : "")://" + host + request.url + "/"
        response.status = .movedPermanently
        response.complete()
        return
      }
      url += "index.html"
      if let file = try? Data(contentsOf: URL(fileURLWithPath: url)) {
        response.body = file
        response.contentType = .html
      } else {
        response.status = .notFound
        response.bodyString = notFoundPage
        response.contentType = .html
      }
    }
    
    response.lastModifiedDate = (try? FileManager.default.attributesOfItem(atPath: url))?[FileAttributeKey.modificationDate] as? Date
    
    response.complete()
  }
  
  func handleConnection(socket: ClientSocket) {
    if let socket = socket as? ClientSSLSocket { socket.initSSLConnection(sslContext: sslContext) }
    guard accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) else { return }
    while let request = socket.acceptRequest() {
      let response = Response(clientSocket: socket)
      for accessControlRule in urlAccessControl where
        request.url.starts(with: accessControlRule.url) &&
        !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) {
          response.status = accessControlRule.responseStatus
          continue
      }
      guard case .ok = response.status else {
        response.complete()
        continue
      }
      
      if request.method == .head {
        response.omitBody = true
        request.method = .get
      }
      
      if let handler = getHandlerFor(method: request.method,
                                     url: request.url) {
        handler(request, response)
      } else {
        staticFileHandler(request: request,
                            response: response)
      }
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
