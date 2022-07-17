import Foundation

protocol ProtocolHeader {
  var sourcePort: UInt16 { get }
  var destinationPort: UInt16 { get }
  var size: Int { get }
}
