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
//  E     |                                                               |
//  S  4  |                        Sequence Number                        |
//        |_______________________________________________________________|
//        |                                                               |
//     8  |                           Ack Number                          |
//        |_______________________________________________________________|
//        |       |                       |                               |
//     12 |  Size |     Various Flags     |          Window Size          |
//        |_______|_______________________|_______________________________|
//        |                               |                               |
//     16 |           Checksum            |         Urgent Pointer        |
//        |_______________________________|_______________________________|
//        -                                                               -
//     20 -            Extra Options (Optional, rarely used)              -
//        -...............................................................-
//
struct TCPHeader: ProtocolHeader {
  
  var sourcePort: UInt16
  var destinationPort: UInt16
  var size: Int
  
  static func parse(from dataReader: DataReader) -> TCPHeader? {
    guard let sourcePort = dataReader.uint16(),
          let destinationPort = dataReader.uint16(at: 2),
          let sizeByte = dataReader.byte(at: 12)
    else { return nil }
    
    return TCPHeader(sourcePort: sourcePort,
                     destinationPort: destinationPort,
                     size: Int((sizeByte & 0xf0) >> 4) * 4)
  }
}
