import Foundation

import HelloCore

//  Data Structure
//
//         B I T S
//
//        |1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|1 2 3 4 5 6 7 8|
//        _________________________________________________________________
//  B     |       |       |               |                               |
//  Y  0  |   a   |   b   |       c       |               d               |
//  T     |_______|_______|_______________|_______________________________|
//  E     |                               |   |                           |
//  S  4  |               e               | f |           g               |
//        |_______________________________|___|___________________________|
//        |               |               |                               |
//     8  |       h       |       i       |               j               |
//        |_______________|_______________|_______________________________|
//        |                                                               |
//     12 |                               k                               |
//        |_______________________________________________________________|
//        |                                                               |
//     16 |                               l                               |
//        |_______________________________________________________________|
//        -                                                               -
//     20 -            Extra Options (Optional, rarely used)              -
//        -...............................................................-
//
//
// a - IP version (contant, 4)
// b - IP header length (in 32-bit words)
// c - Type of service or DSCP + ECN
// d - Total size of packet
// e - Identification
// f - Flags to control packet fragmentation
// g - Fragment offset
// i - Protocol
// j - Header checksum
// k - Source Address
// l - Destination Address
//
struct IPV4Header: IPHeader {
  
  var version: IPVersion { .ipv4 }
  var headerSize: Int
  var `protocol`: IPProtocol
  
  static func parse(from dataReader: DataReader) -> IPV4Header? {
    guard
      let firstByte = dataReader.byte(),
      let protocolByte = dataReader.byte(at: 9)
    else { return nil }
    
    return IPV4Header(headerSize: Int(firstByte & 0x0f) * 4,
                      protocol: IPProtocol.infer(from: protocolByte))
  }
}
