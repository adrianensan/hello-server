import Foundation
import CoreFoundation

Task {
  let catGameServer = CatGameServer()
  try await catGameServer.start()
  try await catGameServer.wwwRedirectServer().start()
}

CFRunLoopRun()
