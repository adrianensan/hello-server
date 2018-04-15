import Dispatch
import Foundation

public class Server {
    
    static let supportedHTTPVersions: [String] = ["http/1.1"]
    
    static private func httpToHttpsRedirectServer() -> Server {
        let redirectServer = Server()
        redirectServer.shouldProvideStaticFiles = false
        redirectServer.serverAddress = "adrianensan.me"
        redirectServer.addEndpoint(method: .any, url: "*", handler: {request, response in
            response.status = .movedPermanently
            if let serverAddress = redirectServer.serverAddress {
                response.location = "https://" + serverAddress + request.url
            } else {
                fatalError("serverAddress needs to be set in order to redirect http traffic to https")
            }
            response.complete()
        })
        
        return redirectServer
    }

    public var serverName: String = ""
    public var serverAddress: String?
    public var httpPort: UInt16 = 80
    public var httpsPort: UInt16 = 443
    public var staticDocumentRoot: String {
        get { return documentRoot }
        set { documentRoot = CommandLine.arguments[0] + newValue }
    }
    public var shouldRedirectHttpToHttps: Bool = false
    public var shouldProvideStaticFiles: Bool = true
    
    var endpoints = [(method: Method, url: String, handler: (request: Request, response: Response) -> Void)]()
    
    private var usingTLS = false
    private var documentRoot: String = /*CommandLine.arguments[0] +*/ "./static"
    private var listeningSocket: ServerSocket?
    
    public init() {}
    
    public func useTLS(certificateFile: String, privateKeyFile: String) {
        ClientSSLSocket.initSSLContext(certificateFile: certificateFile, privateKeyFile: privateKeyFile)
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
            print(fileExtension)
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
            DispatchQueue(label: "redirectServer").async {
                Server.httpToHttpsRedirectServer().start()
            }
        }
        DispatchQueue(label: "server").async {
            self.listeningSocket = ServerSocket(port: self.usingTLS ? self.httpsPort : self.httpPort, usingTLS: self.usingTLS)
            while let newClient = self.listeningSocket?.acceptConnection() {
                DispatchQueue(label: "client-\(newClient)").async {
                    self.handleConnection(socket: newClient)
                }
            }
        }
    }
}
