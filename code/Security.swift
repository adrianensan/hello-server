import Foundation

import HelloCore

public struct Security {
  public static var isEnabled: Bool = false
  public static var maxConnectionPerClient: Int = 20
  private static var hasStarted: Bool = false
  private static var openConnections: [NetworkAddress: Int] = [:]
  private static var clientReputation: [NetworkAddress: Double] = [:]
  
  static func shouldAllowConnection(from address: NetworkAddress) -> Bool {
    guard isEnabled else { return true }
    if openConnections[address] ?? 0 < maxConnectionPerClient && !clientHasBadReputation(address: address) { return true }
    else { return false }
  }
  
  static func connectionOpened(address: NetworkAddress) {
    guard isEnabled else { return }
    openConnections[address] = (openConnections[address] ?? 0) + 1
    clientReputation[address] = (clientReputation[address] ?? 1) - 0.02
  }
  
  static func connectionClosed(address: NetworkAddress) {
    guard isEnabled else { return }
    openConnections[address]? -= 1
  }
  
  static func requestRecieved(from address: NetworkAddress) {
    guard isEnabled else { return }
    clientReputation[address] = (clientReputation[address] ?? 1) - 0.001
  }
  
  static func clientHasBadReputation(address: NetworkAddress) -> Bool {
    guard isEnabled else { return false }
    return clientReputation[address] ?? 1 < 0.5
  }
  
  static func startSecurityMonitor() {
    guard isEnabled && !hasStarted else { return }
    hasStarted = true
    Task {
      while true {
        Log.debug("Loop 20", context: "Loop")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
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
