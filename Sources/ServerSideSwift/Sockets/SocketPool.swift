import Foundation

import HelloLog

enum SocketState {
  case closed
  case readyToRead
  case idle
}

class PoolCancelSignal {
  
  private let inputFD: Int32
  let outputFD: Int32
  
  init() {
    var fds: [Int32] = [0, 0]
    guard pipe(&fds) == 0 else {
      fatalError("Failed to pipe")
    }
    inputFD = fds[1]
    outputFD = fds[0]
    guard fcntl(inputFD, F_SETFL, O_NONBLOCK) >= 0 && fcntl(outputFD, F_SETFL, O_NONBLOCK) >= 0 else {
      fatalError()
    }
  }
  
  func cancel() {
    var cancelString = "1"
    write(inputFD, &cancelString, 1)
  }
  
  func reset() {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: 10)
    read(outputFD, &recieveBuffer, 10)
  }
}

class SocketPoller {
  
  var cancelSocket = PoolCancelSignal()
  var observedSockets: Set<Int32> = []
  var stateUpdateListener: ([Int32: SocketState]) async -> Void = { _ in }
  
  init() {
    Thread.detachNewThread {
      self.pollEventLoop()
    }
  }
  
  func update(observedSockets: Set<Int32>) {
    self.observedSockets = observedSockets
    cancelSocket.cancel()
  }
  
  private func pollEventLoop() {
    while true {
      var pollfds = ([cancelSocket.outputFD] + observedSockets).map {
        pollfd(fd: $0, events: Int16(POLLIN | POLLPRI), revents: 0)
      }
      Log.info("waiting on \(pollfds.count - 1) sockets", context: "Poll")
      poll(&pollfds, nfds_t(pollfds.count), -1)
      cancelSocket.reset()
      var socketStates: [Int32: SocketState] = [:]
      for pollSocket in pollfds where pollSocket.fd != cancelSocket.outputFD {
        socketStates[pollSocket.fd] = .idle
        if pollSocket.revents != 0 {
          if pollSocket.revents & Int16(POLLERR | POLLHUP | POLLNVAL) != 0 {
            socketStates[pollSocket.fd] = .closed
          } else if pollSocket.revents & Int16(POLLIN | POLLPRI) != 0 {
            socketStates[pollSocket.fd] = .readyToRead
          } else {
            Log.error("Unhandled events \(pollSocket.revents)", context: "Poll")
          }
        }
      }
      if socketStates.contains(where: { $0.value != .idle }) {
        Log.info("poll done", context: "Poll")
        for socketState in socketStates where socketState.value != .idle {
          observedSockets.remove(socketState.key)
        }
        let socketStates = socketStates
        Task { await stateUpdateListener(socketStates) }
      }
    }
  }
}

actor SocketPool {
  
  static var main: SocketPool = SocketPool()
  
  var poller: SocketPoller = SocketPoller()
  
  init() {
    poller.stateUpdateListener = { states in
      Task { await self.pollStateUpdate(states) }
    }
  }
  
  var sockets: Set<Int32> = []
  var pollTask: Task<[Int32: SocketState], any Error>?
  var socketListeners: [Int32: CheckedContinuation<Void, Error>] = [:]
  
  @Sendable
  func pollStateUpdate(_ socketStates: [Int32: SocketState]) async {
    for socketState in socketStates where socketState.value != .idle {
      sockets.remove(socketState.key)
      guard let continuation = socketListeners[socketState.key] else { continue }
      socketListeners[socketState.key] = nil
      switch socketState.value {
      case .closed:
        continuation.resume(throwing: SocketError.closed)
      case .readyToRead:
        continuation.resume()
      case .idle: continue
      }
    }
  }
  
  func waitForChange(on socket: Socket) async throws -> Void {
    if !sockets.contains(socket.socketFileDescriptor) {
      sockets.insert(socket.socketFileDescriptor)
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      addListener(continuation, to: socket.socketFileDescriptor)
      poller.update(observedSockets: sockets)
    }
  }
  
  func addListener(_ continuation: CheckedContinuation<Void, Error>, to fd: Int32) {
    if let existingContinuation = socketListeners[fd] {
      Log.error("Trying to wait for fd that's already ben waited for", context: "Poller")
      existingContinuation.resume(throwing: SocketError.closed)
    }
    socketListeners[fd] = continuation
  }
}
