import Foundation

class Socket {
    
    #if os(Linux)
    let socketStremType = Int32(SOCK_STREAM.rawValue)
    
    private func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
        return htons(port)
    }
    #else
    let socketStremType = SOCK_STREAM
    
    private func hostToNetworkByteOrder(_ port: UInt16) -> in_port_t {
        let portTemp = in_port_t(port)
        return Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(portTemp) : portTemp
    }
    #endif
    
    let acceptBacklog: Int32 = 20
    let bufferSize = 100 * 1024
    
    let socketFileDescriptor: Int32
    
    init(port: UInt16) {
        socketFileDescriptor = socket(AF_INET, socketStremType, 0)
        guard socketFileDescriptor >= 0 else { fatalError("Failed to initialize socket") }
        
        var value = 1
        guard setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value,
                         socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                            fatalError("setsockopt failed.")
        }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET);
        addr.sin_port = hostToNetworkByteOrder(port);
        addr.sin_addr.s_addr = INADDR_ANY;
        var saddr = sockaddr()
        memcpy(&saddr, &addr, MemoryLayout<sockaddr_in>.size)
        guard bind(socketFileDescriptor, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else {
            fatalError("bind failed.")
        }
        
        guard listen(socketFileDescriptor, acceptBacklog) != -1 else {
            fatalError("listen failed.")
        }
    }
    
    init(socketFD: Int32) {
        socketFileDescriptor = socketFD;
    }
    
    deinit {
        close(socketFileDescriptor)
    }
    
    func acceptConnection() -> Socket? {
        let newConnectionFD = accept(socketFileDescriptor, nil, nil)
        guard newConnectionFD != -1 else { return nil }
        return Socket(socketFD: newConnectionFD)
    }
    
    func acceptRequest() -> Request? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: bufferSize)
        var requestLength: Int = 0
        while true {
            let bytesRead = recv(socketFileDescriptor, &requestBuffer[requestLength], bufferSize - requestLength, 0)
            guard bytesRead > 0 else { return nil }
            return Request()
        }
    }
    
    func sendResponse(_ response: Response) {
        let response =
            """
            HTTP/1.1 200 OK
            Content-Type: text/html
            Content-Length: 52

            <html>
            <body>
            <h1>Hello, World!</h1>
            </body>
            </html>
            """
        let bytes = [UInt8](response.utf8)
        let sent = send(socketFileDescriptor, bytes, bytes.count, 0);
    }
}
