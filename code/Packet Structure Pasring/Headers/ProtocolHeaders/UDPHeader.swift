import Foundation

//  Data Structure
//
//         B I T S
//
//        |1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|
//        _________________________________________________________________
//  B     |                               |                               |
//  Y  0  |         Source Port           |       Destination Port        |
//  T     |_______________________________|_______________________________|
//  E     |                               |                               |
//  S  4  |          Total Size           |           Checksum            |
//        |_______________________________|_______________________________|
//
struct UDPHeader: ProtocolHeader {
  
  var sourcePort: UInt16
  var destinationPort: UInt16
  var size: Int { 8 }
  
  static func parse(from dataReader: DataReader) -> UDPHeader? {
    guard let sourcePort = dataReader.uint16(),
          let destinationPort = dataReader.uint16(at: 2)
    else { return nil }
    
    return UDPHeader(sourcePort: sourcePort,
                     destinationPort: destinationPort)
  }
}
