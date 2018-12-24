import Foundation
import OpenSSL

class ClientSSLSocket: ClientSocket {
    
    /*
    func infoCallback(ssl: UnsafePointer<SSL>?, type: Int32, alertInfo: Int32) {
        if (type & SSL_CB_HANDSHAKE_START != 0) {
            
        }
    }*/
    
    var sslSocket: UnsafeMutablePointer<SSL>!
    
    func initSSLConnection(sslContext: UnsafeMutablePointer<SSL_CTX>) {
        sslSocket = SSL_new(sslContext);
        SSL_set_fd(sslSocket, socketFileDescriptor);
        //SSL_CTX_set_info_callback(sslContext, infoCallback)
        let ssl_err = SSL_accept(sslSocket);
        if ssl_err <= 0 { close(socketFileDescriptor) }
    }
    
    override func sendData(data: [UInt8]) {
        var bytesToSend = data.count
        repeat {
            let bytesSent = SSL_write(sslSocket, data, Int32(bytesToSend))
            if bytesSent <= 0 { return }
            bytesToSend -= Int(bytesSent)
        } while bytesToSend > 0
    }
    
    override func acceptRequest() -> Request? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
        var requestLength: Int = 0
        while true {
            let bytesRead = SSL_read(sslSocket, &requestBuffer[requestLength], Int32(Socket.bufferSize - requestLength))
            guard bytesRead > 0 else { return nil }
            requestLength += Int(bytesRead)
            Security.requestRecieved(from: ipAddress)
            return Security.clientHasBadReputation(ipAddress: ipAddress) ? nil : Request.parse(data: requestBuffer[..<requestLength].filter{$0 != 13})
        }
    }
}
