import Foundation

extension UInt16 {
  init(_ byte1: UInt8, _ byte2: UInt8) {
    self = UInt16(byte1) << 8 | UInt16(byte2)
  }
}

extension UInt32 {
  init(_ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8, _ byte4: UInt8) {
    self = UInt32(byte1) << 24 | UInt32(byte2) << 16 | UInt32(byte3) << 8 | UInt32(byte4)
  }
}
