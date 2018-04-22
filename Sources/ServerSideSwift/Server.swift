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

public class Server {
    
    static let supportedHTTPVersions: [String] = ["http/1.1"]
    
    public enum ConnectionHandling {
        case acceptAll
        case acceptMatchingHost
        case redirectNonMatchingHostToHost
    }
    
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
    
    private func httpToHttpsRedirectServer(host: String,
                                           connectionHandling: ConnectionHandling) -> Server {
        let redirectServer = Server(host: host)
        redirectServer.shouldProvideStaticFiles = false
        redirectServer.connectionHandling = connectionHandling
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
        set { documentRoot = /*CommandLine.arguments[0] +*/ newValue }
    }
    public var accessControl: AccessControl = .acceptAll(blacklist: [])
    public var pageAccessControl: [(url: String, accessControl: AccessControl, responseStatus: ResponseStatus)] = []
    public var connectionHandling: ConnectionHandling = .acceptAll
    public var shouldRedirectHttpToHttps: Bool = false
    public var shouldProvideStaticFiles: Bool = true
    
    private var host: String
    private var usingTLS = false
    private var documentRoot: String = /*CommandLine.arguments[0] +*/ "./static"
    private var endpoints = [(method: Method, url: String, handler: (request: Request, response: Response) -> Void)]()
    
    private var sslContext: UnsafeMutablePointer<SSL_CTX>!
    
    private func initSSLContext(certificateFile: String, privateKeyFile: String) {
        SSL_load_error_strings();
        SSL_library_init();
        OpenSSL_add_all_digests();
        sslContext = SSL_CTX_new(TLSv1_2_server_method())
        SSL_CTX_set_alpn_select_cb(sslContext, alpn_select_callback, nil)
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
    
    func addPageSpecificAccessControl(subDirectory: String, accessControl: AccessControl, responseStatus: ResponseStatus) {
        pageAccessControl.append((url: subDirectory, accessControl: accessControl, responseStatus: responseStatus))
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
        guard accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) else { return }
        while let request = socket.acceptRequest() {
            let response = Response(clientSocket: socket)
            for accessControlRule in pageAccessControl where
                request.url.starts(with: accessControlRule.url) &&
                !accessControlRule.accessControl.shouldAllowAccessTo(ipAddress: socket.ipAddress) {
                    response.status = accessControlRule.responseStatus
                    continue
            }
            guard case .ok = response.status else { continue }
            
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
            Router.addServer(host: host, port: httpPort, usingTLS: false, server: httpToHttpsRedirectServer(host: host, connectionHandling: connectionHandling))
        }
        Router.addServer(host: host, port: self.usingTLS ? self.httpsPort : self.httpPort, usingTLS: usingTLS, server: self)
    }
}
