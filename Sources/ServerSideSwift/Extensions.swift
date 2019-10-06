import Foundation

extension String {
    
  static let lineBreak: String = "\r\n"
  
  var data: Data { return data(using: .utf8) ?? Data() }
  
  var filterNewlines: String { return filter{ !String.lineBreak.contains($0) } }
  
  var trimWhitespace: String { return trimmingCharacters(in: .whitespaces) }
  var trimNewlines: String { return trimmingCharacters(in: .newlines) }
}

extension Array where Element == UInt8 {
  var intValue: Int {
    var result: Int = 0
    for i in 0..<count {
      result += Int(self[i]) << (8 * (count - i - 1))
    }
    return result
  }
}
