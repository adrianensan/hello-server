import Foundation

public class Message {
  static func findHeaderEnd(data: [UInt8]) -> Int? {
    for i in 0..<(data.count - 1) {
      if data[i] == 10 && data[i + 1] == 10 {
        return i
      }
    }
    
    return nil
  }
  
  var body: Data = Data()
  var bodyString: String {
    set { body = Data(newValue.utf8) }
    get { return String(data: body, encoding: .utf8) ?? "" }
  }
}
