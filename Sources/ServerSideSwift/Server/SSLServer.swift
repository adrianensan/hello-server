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

public class SSLServer: Server {
  
  override var httpUrlPrefix: String { "https://" }
  
  public let sslContext: UnsafeMutablePointer<SSL_CTX>!
  
  init(host: String,
       port: UInt16,
       staticFilesRoot: String?,
       endpoints: [ServerEndpoint],
       urlAccessControl: [URLAccess],
       sslFiles: ServerBuilder.SSLFiles) {
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
    super.init(host: host, port: port, staticFilesRoot: staticFilesRoot, endpoints: endpoints, urlAccessControl: urlAccessControl)
  }
  
  func handleConnection(socket: ClientSSLSocket) {
    socket.initSSLConnection(sslContext: sslContext)
    super.handleConnection(socket: socket)
  }

}
