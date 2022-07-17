import Foundation

public struct IPv4Address: IPAddressConformable {
  
  enum IPv4AddressError: Error {
    case invalidIPv4Address
  }
  
  public var type: IPVersion { .ipv4 }
  
  public let bytes: [UInt8]
  
  public init(_ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8, _ byte4: UInt8) {
    bytes = [byte1, byte2, byte3, byte4]
  }
  
  init(_ bytes: [UInt8]) throws {
    guard bytes.count == 4 else {
      throw IPv4AddressError.invalidIPv4Address
    }
    self.bytes = bytes
  }
  
  public init(_ string: String) throws {
    bytes = string
      .components(separatedBy: ".")
      .compactMap { UInt8($0) }
    guard bytes.count == 4 else {
      throw IPv4AddressError.invalidIPv4Address
    }
  }
  
  public init(from ipv4SockAddr: sockaddr_in) throws {
    let addrInt = ipv4SockAddr.sin_addr.s_addr
    self.init(
      UInt8(addrInt & 0x000000ff),
      UInt8((addrInt & 0x0000ff00) >> 8),
      UInt8((addrInt & 0x00ff0000) >> 16),
      UInt8((addrInt & 0xff000000) >> 24)
    )
  }
  
  public var string: String {
    bytes.reduce(into: "") {
      if !$0.isEmpty {
        $0 += "."
      }
      $0 += String($1)
    }
  }
  
  public func systemAddr(with port: UInt16) -> sockaddr {
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_addr.s_addr = inet_addr(string)
    addr.sin_port = ServerSocket.hostToNetworkByteOrder(port)
    
    var saddr = sockaddr()
    memcpy(&saddr, &addr, MemoryLayout<sockaddr_in>.size)
    return saddr
  }
}
