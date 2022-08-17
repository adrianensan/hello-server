import Foundation

import HelloCore

//  Data Structure
//
//         B I T S
//
//        |1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|
//        _________________________________________________________________
//  B     |       |               |                                       |
//  Y  0  |   a   |       b       |                  c                    |
//  T     |_______|_______________|_______________________________________|
//  E     |                               |               |               |
//  S  4  |               d               |       e       |      f        |
//        |_______________________________|_______________|_______________|
//        |                                                               |
//     8  |                                                               |
//        |                                                               |
//        |                                                               |
//     12 |                                                               |
//        |                                                               |
//        |                               g                               |
//     16 |                                                               |
//        |                                                               |
//        |                                                               |
//     20 |                                                               |
//        |_______________________________________________________________|
//        |                                                               |
//     24 |                                                               |
//        |                                                               |
//        |                                                               |
//     28 |                                                               |
//        |                                                               |
//        |                               h                               |
//     32 |                                                               |
//        |                                                               |
//        |                                                               |
//     36 |                                                               |
//        |_______________________________________________________________|
//
//
// a - IP version (constant, 6)
// b - Traffic Class
// c - Flow label
// d - Total size of packet
// e - Protocol (Next Header Type)
// f - Hop limit
// g - Source Address
// i - Destination Address
//
struct IPV6Header: IPHeader {
  
  var version: IPVersion { .ipv6 }
  var headerSize: Int { 40 }
  var `protocol`: IPProtocol
  
  static func parse(from dataReader: DataReader) -> IPV6Header? {
    guard let protocolByte = dataReader.byte(at: 6) else { return nil }
    
    return IPV6Header(protocol: .infer(from: protocolByte))
  }
}
