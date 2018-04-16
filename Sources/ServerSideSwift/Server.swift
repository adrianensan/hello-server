import Dispatch
import Foundation
import COpenSSL

public class Server {
    
    static let supportedHTTPVersions: [String] = ["http/1.1"]
    
    public enum ConnectionHandling {
        case acceptAll
        case acceptMatchingHost
        case redirectNonMatchingHostToHost
    }
    
    static private func httpToHttpsRedirectServer(host: String) -> Server {
        let redirectServer = Server(host: host)
        redirectServer.shouldProvideStaticFiles = false
        redirectServer.addEndpoint(method: .any, url: "*", handler: {request, response in
            response.status = .movedPermanently
            response.location = "https://" + host + request.url
            response.complete()
        })
        
        return redirectServer
    }

    public var serverName: String = ""
    public var httpPort: UInt16 = 80
    public var httpsPort: UInt16 = 443
    public var staticDocumentRoot: String {
        get { return documentRoot }
        set { documentRoot = CommandLine.arguments[0] + newValue }
    }
    public var connectionHandling: ConnectionHandling = .acceptAll
    public var shouldRedirectHttpToHttps: Bool = false
    public var shouldProvideStaticFiles: Bool = true
    
    var endpoints = [(method: Method, url: String, handler: (request: Request, response: Response) -> Void)]()
    
    private var host: String
    private var usingTLS = false
    private var documentRoot: String = /*CommandLine.arguments[0] +*/ "./static"
    private var listeningSocket: ServerSocket?
    
    private var sslContext: UnsafeMutablePointer<SSL_CTX>!
    
    private func initSSLContext(certificateFile: String, privateKeyFile: String) {
        SSL_load_error_strings();
        SSL_library_init();
        OpenSSL_add_all_digests();
        sslContext = SSL_CTX_new(TLSv1_2_server_method())
        SSL_CTX_set_alpn_select_cb(sslContext, cb, nil)
        if SSL_CTX_use_certificate_file(sslContext, certificateFile , SSL_FILETYPE_PEM) != 1 {
            fatalError("Failed to use provided certificate file")
        }
        if SSL_CTX_use_PrivateKey_file(sslContext, privateKeyFile, SSL_FILETYPE_PEM) != 1 {
            fatalError("Failed to use provided preivate key file")
        }
    }
    
    public init(host: String) {
        self.host = host
    }
    
    public func useTLS(certificateFile: String, privateKeyFile: String) {
        initSSLContext(certificateFile: certificateFile, privateKeyFile: privateKeyFile)
        usingTLS = true
    }
    
    func addEndpoint(method: Method, url: String, handler: @escaping (Request, Response) -> Void) {
        endpoints.append((method: method, url: url, handler: handler))
    }
    
    func getHandlerFor(method: Method, url: String) -> ((Request, Response) -> Void)? {
        for handler in endpoints {
            if handler.method == .any || handler.method == method {
                if let end = handler.url.index(of: "*") {
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
        var url = staticDocumentRoot + request.url
        
        if let file = try? String(contentsOf: URL(fileURLWithPath: url), encoding: .utf8) {
            var fileExtension = ""
            let splits = url.split(separator: "/", omittingEmptySubsequences: true)
            if let fileName = splits.last {
                let fileNameSplits = fileName.split(separator: ".")
                if let potentialExtension = fileNameSplits.last { fileExtension = String(potentialExtension) }
            }
            response.body = file
            response.contentType = .from(fileExtension: fileExtension)
        } else {
            if url.last ?? " " != "/" { url += "/" }
            if let file = try? String(contentsOf: URL(fileURLWithPath: url + "index.html"), encoding: .utf8) {
                response.body = file
                response.contentType = .html
            } else {
                response.status = .notFound
                response.body = notFoundPage
                response.contentType = .html
            }
        }
        
        response.complete()
    }
    
    func handleConnection(socket: ClientSocket) {
        if let socket = socket as? ClientSSLSocket { socket.initSSLConnection(sslContext: sslContext) }
        while let request = socket.acceptRequest() {
            let response = Response(clientSocket: socket)
            if request.method == .head {
                response.omitBody = true
                request.method = .get
            }
            
            if let handler = getHandlerFor(method: request.method, url: request.url) {
                handler(request, response)
            } else {
                staticFileHandler(request: request, response: response)
            }
        }
    }
    
    public func start() {
        if shouldRedirectHttpToHttps {
            Router.addServer(host: host, port: httpPort, usingTLS: false, server: Server.httpToHttpsRedirectServer(host: host))
        }
        Router.addServer(host: host, port: self.usingTLS ? self.httpsPort : self.httpPort, usingTLS: usingTLS, server: self)
    }
}
