import Foundation

import HelloCore

public enum DNSLabel {
  
  public static func parseDomain(from dataReader: DataReader,
                                 labelPointers: inout [Int: String],
                                 packetOffset: inout Int) -> String? {
    var domain: String = ""
    var newLabelPointers: [Int: String] = [:]
    while let firstByte = dataReader.byte() {
      Log.debug("Loop 9", context: "Loop")
      // 0 signals the end of a domain
      if firstByte == 0 {
        dataReader.advanceCursor(by: 1)
        packetOffset += 1
        break
      }
      if !domain.isEmpty {
        domain += "."
      }
      
      let label: String
      
      // If the first 2 bits are set (greater than 64),
      // this is a 16 bit pointer to a label previously visited in the packet
      if firstByte > 63 {
        guard let pointerPositionInt = dataReader.uint16() else { return nil }
        let pointerPosition = Int(pointerPositionInt & 0b0011111111111111)
        guard let pointerLabel = labelPointers[pointerPosition] else { return nil }
        label = pointerLabel
        dataReader.advanceCursor(by: 2)
      } else {
        // if the first byte is > 0, and < 64, is represents the length of the label to read
        guard let parsedLabelBytes = dataReader.bytes(at: 1, length: Int(firstByte)),
              let parsedLabel = String(bytes: parsedLabelBytes, encoding: .utf8)
        else { return nil }
        label = parsedLabel
        dataReader.advanceCursor(by: 1 + label.count)
      }
      domain += label
      newLabelPointers = newLabelPointers.mapValues { $0 + "." + label }
      newLabelPointers[packetOffset] = label
      if firstByte > 63 {
        packetOffset += 2
        break
      } else {
        packetOffset += 1 + label.count
      }
    }
    
    for (index, string) in newLabelPointers {
      labelPointers[index] = string
    }
    
    return domain
  }
}
