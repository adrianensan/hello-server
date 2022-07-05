import Foundation
import CoreFoundation

let catGameServer = CatGameServer()
catGameServer.start()
catGameServer.wwwRedirectServer().start()

CFRunLoopRun()
