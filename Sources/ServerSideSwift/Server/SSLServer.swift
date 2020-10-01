import Dispatch
import Foundation
import OpenSSL

func alpn_select_callback( _ sslSocket: OpaquePointer?,
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
  
  public let sslContext: OpaquePointer!
  
  init(host: String,
       port: UInt16,
       accessControl: AccessControl,
       staticFilesRoot: String?,
       endpoints: [ServerEndpoint],
       urlAccessControl: [URLAccess],
       sslFiles: SSLFiles) {
    sslContext = SSL_CTX_new(TLS_method())

    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_SSLv2))
    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_SSLv3))
    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1))
    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1_1))

    SSL_CTX_set_alpn_select_cb(sslContext, alpn_select_callback, nil)
    if SSL_CTX_use_certificate_chain_file(sslContext, sslFiles.certificate) != 1 {
      fatalError("Failed to use provided certificate file")
    }
    if SSL_CTX_use_PrivateKey_file(sslContext, sslFiles.privateKey, SSL_FILETYPE_PEM) != 1 {
      fatalError("Failed to use provided preivate key file")
    }

//    let dh_file = fopen(sslFiles.certificate, "r")
//    let dh = PEM_read_DHparams(dh_file, nil, nil, nil)
//    fclose(dh_file)
//    if SSL_CTX_set_tmp_dh(sslContext, dh) != 1 {
//      fatalError("Failed to setup forward secrecy")
//    }
    super.init(host: host, port: port, accessControl: accessControl, staticFilesRoot: staticFilesRoot, endpoints: endpoints, urlAccessControl: urlAccessControl)
  }
  
  override func handleConnection(connection: ClientConnection) {
    guard let connection = connection as? SSLClientConnection else { return }
    guard connection.initAccpetSSLHandshake(sslContext: sslContext) else { return }
    super.handleConnection(connection: connection)
  }

}
