import Foundation
import COpenSSL

func cb( _ sslSocket: UnsafeMutablePointer<SSL>?,
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

class ClientSSLSocket: ClientSocket {
    
    var sslSocket: UnsafeMutablePointer<SSL>!
    
    func initSSLConnection(sslContext: UnsafeMutablePointer<SSL_CTX>) {
        sslSocket = SSL_new(sslContext);
        SSL_set_fd(sslSocket, socketFileDescriptor);
        let ssl_err = SSL_accept(sslSocket);
        if ssl_err <= 0 { close(socketFileDescriptor) }
    }
    
    override func sendData(data: [UInt8]) {
        var bytesToSend = data.count
        repeat {
            let bytesSent = SSL_write(sslSocket, data, Int32(bytesToSend));
            if bytesSent <= 0 { return }
            bytesToSend -= Int(bytesSent)
        } while bytesToSend > 0
    }
    
    override func acceptRequest() -> Request? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
        var requestLength: Int = 0
        while true {
            let bytesRead = SSL_read(sslSocket, &requestBuffer[requestLength], Int32(Socket.bufferSize - requestLength));
            guard bytesRead > 0 else { return nil }
            requestLength += Int(bytesRead)
            if let requestString = String(bytes: requestBuffer[..<requestLength].filter{$0 != 13}, encoding: .utf8) {
                return Request.parse(string: requestString);
            }
        }
    }
}
