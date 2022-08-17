import Foundation
import CoreFoundation

import HelloCore

class UDPServerSocket: UDPSocket {
  
  init(port: UInt16) throws {
    let listeningSocket = socket(AF_INET, SocketType.udp.systemValue, 0)
    
    guard listeningSocket >= 0 else {
      throw SocketError.initFail
    }
    
    try super.init(socketFD: listeningSocket, port: port)
    
    try bindForInbound(to: port)
  }
}
