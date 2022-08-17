import Foundation

public enum IPProtocol: Equatable {
  case tcp
  case udp
  case unknown(number: UInt8)
  
  public static func infer(from protocolInt: UInt8) -> IPProtocol {
    switch protocolInt {
    case 6: return .tcp
    case 17: return .udp
    default: return .unknown(number: protocolInt)
    }
  }
  
  public var name: String {
    switch self {
    case .tcp: return "TCP"
    case .udp: return "UDP"
    case .unknown(let number): return "Unknown (\(number))"
    }
  }
}
