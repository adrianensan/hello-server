import Foundation

public struct IPv6Address: IPAddressConformable {
  
  public var type: IPVersion { .ipv6 }
  
  public let bytes: [UInt8]
  
  public init(_ bytes: [UInt8]) throws {
    guard bytes.count == 16 else {
      throw IPAddressError.invalidIPv4Address
    }
    self.bytes = bytes
  }
  
  public init(_ string: String) throws {
    let components = string.components(separatedBy: ":")
    guard components.count > 3 else {
      throw IPAddressError.invalidIPAddress
    }
    
    var bytes: [UInt8] = []
    var wasLastEmpty: Bool = false
    for component in components {
      if component.isEmpty {
        if wasLastEmpty {
          bytes += .init(repeating: 0, count: (8 - (components.count - 1) * 2))
        } else {
          wasLastEmpty = true
          bytes.append(0)
        }
      } else {
        guard let number = UInt16(component) else {
          throw IPAddressError.invalidIPAddress
        }
        bytes.append(UInt8(number >> 4))
        bytes.append(UInt8(number & 0x00ff))
      }
    }
    self.bytes = bytes
  }
  
  public init(from ipv6SockAddr: sockaddr_in6) throws {
    var ipv6SockAddr = ipv6SockAddr
    var bytes: [Int8] = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))
    inet_ntop(AF_INET, &ipv6SockAddr.sin6_addr, &bytes, socklen_t(INET6_ADDRSTRLEN));
    try self.init(bytes.map { UInt8($0) })
  }
  
  public var string: String {
    bytes.reduce(into: "") {
      if !$0.isEmpty {
        $0 += ":"
      }
      $0 += String($1)
    }
  }
  
  public func systemAddr(with port: UInt16) -> sockaddr {
    var addr = sockaddr_in6()
    addr.sin6_family = sa_family_t(AF_INET6)
    //saddr.sin6_addr = inet_addr(string)
    addr.sin6_port = ServerSocket.hostToNetworkByteOrder(port)
    
    var saddr = sockaddr()
    memcpy(&saddr, &addr, MemoryLayout<sockaddr_in>.size)
    return saddr
  }
}
