import Foundation

let catGameServer = CatGameServer()
catGameServer.start()
catGameServer.wwwRedirectServer().start()

CFRunLoopRun()
