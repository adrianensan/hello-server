import Foundation

class ServerSocket: ClientSocket {
    
    #if os(Linux)
    static let socketStremType = Int32(SOCK_STREAM.rawValue)
    
    static func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
        return htons(port)
    }
    #else
    static let socketStremType = SOCK_STREAM
    
    static func hostToNetworkByteOrder(_ port: UInt16) -> in_port_t {
        let portTemp = in_port_t(port)
        return Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(portTemp) : portTemp
    }
    #endif
    
    let usingTLS: Bool
    
    init(port: UInt16, usingTLS: Bool) {
        self.usingTLS = usingTLS
        let listeningSocket = socket(AF_INET, ServerSocket.socketStremType, 0)
        super.init(socketFD: listeningSocket)
        
        guard socketFileDescriptor >= 0 else { fatalError("Failed to initialize socket") }
        
        var value = 1
        guard setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value,
                         socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                            fatalError("setsockopt failed.")
        }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET);
        addr.sin_port = ServerSocket.hostToNetworkByteOrder(port);
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
    
    deinit {
        close(socketFileDescriptor)
    }
    
    func acceptConnection() -> ClientSocket? {
        let newConnectionFD = accept(socketFileDescriptor, nil, nil)
        guard newConnectionFD != -1 else { return nil }
        if usingTLS {
            return ClientSSLSocket(socketFD: newConnectionFD)
        } else {
            return ClientSocket(socketFD: newConnectionFD)
        }
    }
}
