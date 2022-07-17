import Foundation

@MainActor
public protocol LoggerSubscriber: AnyObject {
  func statementLogged()
}

public class Logger {
  
  public let logFile: URL
  public private(set) var logStatements: [LogStatement]
  public weak var subscriber: LoggerSubscriber?
  
  private var lastLoggedTime: TimeInterval = 0
  private var isFlushPending: Bool = false
  
  public init(logFile: URL) {
    self.logFile = logFile
//    if let data = try? Data(contentsOf: logFile),
//       let logStatements = try? JSONDecoder().decode([LogStatement].self, from: data) {
//      self.logStatements = logStatements
//    } else {
      logStatements = []
//    }
    
    if !FileManager.default.fileExists(atPath: logFile.deletingLastPathComponent().path) {
      try? FileManager.default.createDirectory(at: logFile.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
  }
  
  private func generateRawString() -> String {
    logStatements.reduce("") { $0 + $1.formattedLine + "\n" }
  }
  
  private var dispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .userInitiated, attributes: [])
  
  public func log(_ logStatement: LogStatement) {
    logStatements.append(logStatement)
    dispatchQueue.async {
      self.lastLoggedTime = Date().timeIntervalSince1970
      Task { await self.subscriber?.statementLogged() }
      if !self.isFlushPending {
        self.isFlushPending = true
        self.flush()
      }
    }
  }
  
  public func clear() {
    dispatchQueue.async {
      self.logStatements = []
      Task { await self.subscriber?.statementLogged() } 
      if !self.isFlushPending {
        self.isFlushPending = true
        self.flush()
      }
    }
  }
  
  public func flush(force: Bool = false) {
    guard !force else {
      self.flushReal()
      self.isFlushPending = false
      return
    }
    dispatchQueue.async {
      guard self.isFlushPending else { return }
      let diff = Date().timeIntervalSince1970 - self.lastLoggedTime
      guard diff > 5 else {
        self.dispatchQueue.asyncAfter(deadline: .now() + diff + 0.2) {
          self.flush()
        }
        return
      }
      self.isFlushPending = false
      let oldestAllowed = Date().timeIntervalSince1970 - 60 * 60 * 24 * 2
      self.logStatements = Array(self.logStatements.drop(while: { $0.timeStamp < oldestAllowed }))
      self.flushReal()
    }
  }
  
  private func flushReal() {
    guard let logStatementsDate = try? JSONEncoder().encode(self.logStatements) else { return }
    try? logStatementsDate.write(to: self.logFile)
  }
}
