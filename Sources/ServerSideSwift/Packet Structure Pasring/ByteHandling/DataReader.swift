import Foundation

public class DataReader {
  
  private var bytes: [UInt8]
  private var dataLength: Int
  private var cursor: Int
  
  public init(_ data: Data) {
    bytes = [UInt8](data)
    dataLength = bytes.count
    cursor = 0
  }
  
  public init(_ bytes: [UInt8]) {
    self.bytes = bytes
    dataLength = bytes.count
    cursor = 0
  }
  
  public var isValid: Bool {
    cursor < dataLength
  }
  
  public func advanceCursor(by offset: Int) {
    cursor += offset
  }
  
  public func bit(at offset: Int = 0) -> UInt8? {
    guard cursor + offset < dataLength else { return nil }
    return bytes[cursor + offset] & 0b10000000 == 0 ? 0 : 1
  }
  
  public func byte(at offset: Int = 0) -> UInt8? {
    uint8(at: offset)
  }
  
  public func bytes(at offset: Int = 0, length: Int) -> [UInt8]? {
    guard cursor + offset + length <= dataLength else { return nil }
    return [UInt8](bytes[(cursor + offset)..<(cursor + offset + length)])
  }
  
  public func uint8(at offset: Int = 0) -> UInt8? {
    guard cursor + offset < dataLength else { return nil }
    return bytes[cursor + offset]
  }
  
  public func uint16(at offset: Int = 0) -> UInt16? {
    guard cursor + offset + 1 < dataLength else { return nil }
    return UInt16(bytes[cursor + offset], bytes[cursor + offset + 1])
  }
  
  public func uint32(at offset: Int = 0) -> UInt32? {
    guard cursor + offset + 3 < dataLength else { return nil }
    return UInt32(bytes[cursor + offset],
                  bytes[cursor + offset + 1],
                  bytes[cursor + offset + 2],
                  bytes[cursor + offset + 3])
  }
  
}
