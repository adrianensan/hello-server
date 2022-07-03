import Foundation

public enum Log {
  
  private static var logsFolder: URL { FileManager.default.temporaryDirectory.appendingPathComponent("logs") }
  
  public static var logger: Logger = Logger(logFile: logsFolder.appendingPathComponent("logs.txt"))
  
  private static func log(level: LogLevel, message: String, context: String) {
    let logStatement = LogStatement(level: level, message: message, context: context)
    #if DEBUG
    print(logStatement.formattedLine)
    logger.log(logStatement)
    #else
    if level != .debug {
      logger.log(logStatement)
    }
    #endif
  }
  
  public static func verbose(_ message: String, context: String) {
    log(level: .verbose, message: message, context: context)
  }
  
  public static func debug(_ message: String, context: String) {
    log(level: .debug, message: message, context: context)
  }
  
  public static func info(_ message: String, context: String) {
    log(level: .info, message: message, context: context)
  }
  
  public static func warning(_ message: String, context: String) {
    log(level: .warning, message: message, context: context)
  }
  
  public static func error(_ message: String, context: String) {
    log(level: .error, message: message, context: context)
  }
}

