import CoreFoundation

let server = Server()
//server.httpPort = 8181
let keyPath = "/etc/letsencrypt/live/adrianensan.me/privkey.pem"
let certPath = "/etc/letsencrypt/live/adrianensan.me/fullchain.pem"
server.useTLS(certificateFile: certPath, privateKeyFile: keyPath)
server.shouldRedirectHttpToHttps = true
server.start()

CFRunLoopRun()
