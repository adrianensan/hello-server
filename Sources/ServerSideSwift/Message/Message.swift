import Foundation

public class Message {
  
  static func findHeaderEnd(data: [UInt8]) -> Int? {
    for i in 0..<(data.count - 1) {
      if data[i] == .newlineCharacter && data[i + 1] == .newlineCharacter {
        return i
      }
    }
    
    return nil
  }
  
  static func findMessageEnd(data: [UInt8]) -> Int? {
    for i in (0..<(data.count - 1)).reversed() {
      if data[i] == .newlineCharacter && data[i + 1] == 10 {
        return i
      }
    }
    
    return nil
  }
  
  public var body: Data = Data()
  public var bodyString: String {
    set { body = newValue.data }
    get { String(data: body, encoding: .utf8) ?? "" }
  }
}
