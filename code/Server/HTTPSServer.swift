import Foundation

import HelloCore
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
      for httpVersion in ["http/1.1"] {
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

public enum TLSVersion {
  case tls1
  case tls1_1
  case tls1_2
  case tls1_3
}

public protocol SSLServer: TCPServer {
  var sslFiles: SSLFiles { get }
  var sslContext: OpaquePointer! { get set }
  
  func setupSSL() throws
  func handleConnection(sslConnection: SSLClientConnection) async throws
}

public protocol HTTPSServer: SSLServer, HTTPServer {
}

public extension HTTPSServer {
  
  var port: UInt16 { 443 }
  
  func setupSSL() throws {
    Log.info("Setting up SSL", context: "SSL")
    sslContext = SSL_CTX_new(TLS_server_method())

//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_SSLv2))
//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_SSLv3))
//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1))
//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1_1))
//
//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1_2))
//    SSL_CTX_set_options(sslContext, UInt(SSL_OP_NO_TLSv1_3))
    
    SSL_CTX_set_cipher_list(sslContext, "DEFAULT")

    var supportedProtocols = [UInt8]("8http/1.1".data)
    SSL_CTX_set_alpn_protos(sslContext, &supportedProtocols, 9)
//    SSL_CTX_set_alpn_select_cb(sslContext, alpn_select_callback, nil)
    if SSL_CTX_use_certificate_chain_file(sslContext, sslFiles.certificate) != 1 {
      throw SSLError.certFail
    }
    if SSL_CTX_use_PrivateKey_file(sslContext, sslFiles.privateKey, SSL_FILETYPE_PEM) != 1 {
      throw SSLError.privateKeyFail
    }
    
//    SSL_set_read_ahead(sslContext, 1)
    
//    let dh_file = fopen(sslFiles.certificate, "r")
//    let dh = PEM_read_DHparams(dh_file, nil, nil, nil)
//    fclose(dh_file)
//    if SSL_CTX_set_tmp_dh(sslContext, dh) != 1 {
//      fatalError("Failed to setup forward secrecy")
//    }
  }
  
  func handleConnection(sslConnection: SSLClientConnection) async throws {
    #if !DEBUG
    try await sslConnection.initAccpetSSLHandshake(sslContext: sslContext)
    #endif
    try await handleConnection(connection: sslConnection)
  }
    
  func start() async throws {
    #if !DEBUG
    try setupSSL()
    #endif
    try await Router.add(server: self)
  }
}
