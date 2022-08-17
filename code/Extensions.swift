import Foundation

extension String {
    
  static let lineBreak: String = "\r\n"
  
  var data: Data { data(using: .utf8) ?? Data() }
  
  var filterNewlines: String { filter{ !String.lineBreak.contains($0) } }
  
  var trimWhitespace: String { trimmingCharacters(in: .whitespaces) }
  var trimNewlines: String { trimmingCharacters(in: .newlines) }
  
  var fileExtension: String? {
    let splits = split(separator: "/", omittingEmptySubsequences: true)
    guard let fileName = splits.last else { return nil }
    let fileNameSplits = fileName.split(separator: ".")
    guard let potentialFileExtension = fileNameSplits.last else { return nil }
    return String(potentialFileExtension)
  }
}

extension URL {
  var fileExtension: String? {
    let splits = path.split(separator: "/", omittingEmptySubsequences: true)
    guard let fileName = splits.last else { return nil }
    let fileNameSplits = fileName.split(separator: ".")
    guard let potentialFileExtension = fileNameSplits.last else { return nil }
    return String(potentialFileExtension)
  }
}

extension UInt8 {
  public static let nullCharacter: UInt8 = "\0".first!.asciiValue!
  public static let newlineCharacter: UInt8 = "\n".first!.asciiValue!
}

extension Array where Element == UInt8 {
  
  public static let nullCharacter: UInt8 = "\0".first!.asciiValue!
  public static let newlineCharacter: UInt8 = "\n".first!.asciiValue!
  
  var intValue: Int {
    var result: Int = 0
    for i in 0..<count {
      result += Int(self[i]) << (8 * (count - i - 1))
    }
    return result
  }
}
