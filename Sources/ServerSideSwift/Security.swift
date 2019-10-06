import Dispatch
import Foundation

public struct Security {
  public static var isEnabled: Bool = false
  public static var maxConnectionPerClient: Int = 20
  private static var hasStarted: Bool = false
  private static var openConnections: [String: Int] = [:]
  private static var clientReputation: [String: Double] = [:]
  
  static func shouldAllowConnection(from ipAddress: String) -> Bool {
    guard isEnabled else { return true }
    if openConnections[ipAddress] ?? 0 < maxConnectionPerClient && !clientHasBadReputation(ipAddress: ipAddress) { return true }
    else { return false }
  }
  
  static func connectionOpened(ipAddress: String) {
    guard isEnabled else { return }
    openConnections[ipAddress] = (openConnections[ipAddress] ?? 0) + 1
    clientReputation[ipAddress] = (clientReputation[ipAddress] ?? 1) - 0.02
  }
  
  static func connectionClosed(ipAddress: String) {
    guard isEnabled else { return }
    openConnections[ipAddress]? -= 1
  }
  
  static func requestRecieved(from ipAddress: String) {
    guard isEnabled else { return }
    clientReputation[ipAddress] = (clientReputation[ipAddress] ?? 1) - 0.001
  }
  
  static func clientHasBadReputation(ipAddress: String) -> Bool {
    guard isEnabled else { return false }
    return clientReputation[ipAddress] ?? 1 < 0.5
  }
  
  static func startSecurityMonitor() {
    guard isEnabled && !hasStarted else { return }
    hasStarted = true
    DispatchQueue(label: "security-monitor").async {
      while true {
        sleep(1)
        for (client, reputation) in clientReputation {
          clientReputation[client] = max(0.1, min(1, reputation + 0.5 * reputation))
          if clientReputation[client] == 1 && openConnections[client] ?? 0 == 0 {
            clientReputation.removeValue(forKey: client)
            openConnections.removeValue(forKey: client)
          }
        }
      }
    }
  }
}
