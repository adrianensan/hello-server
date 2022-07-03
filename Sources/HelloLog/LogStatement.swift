import Foundation

public struct LogStatement: Codable, Identifiable {
  public var id: String = UUID().uuidString
  public var level: LogLevel
  public var timeStamp: TimeInterval
  public var message: String
  public var context: String
  
  public init(level: LogLevel, message: String, context: String, timeStamp: TimeInterval = Date().timeIntervalSince1970) {
    self.level = level
    self.message = message
    self.context = context
    self.timeStamp = timeStamp
  }
  
  public var timeStampString: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm:ss"
    return dateFormatter.string(from: Date(timeIntervalSince1970: timeStamp))
  }
  
  public var formattedLine: String {
    "[\(level)] \(timeStampString) [\(context)] \(message)"
  }
}
