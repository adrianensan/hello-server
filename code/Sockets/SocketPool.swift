import Foundation

import HelloCore

enum SocketState {
  case closed
  case readyToRead
  case readyToWrite
  case readyToReadAndWrite
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
  var readObservedSockets: Set<Int32> = []
  var writeObservedSockets: Set<Int32> = []
  var stateUpdateListener: ([Int32: SocketState]) -> Void = { _ in }
  
  init() {
    Thread.detachNewThread {
      self.pollEventLoop()
    }
  }
  
  func update(readObservedSockets: Set<Int32>) {
    self.readObservedSockets = readObservedSockets
    cancelSocket.cancel()
  }
  
  func update(writeObservedSockets: Set<Int32>) {
    self.writeObservedSockets = writeObservedSockets
    cancelSocket.cancel()
  }
  
  private func pollEventLoop() {
    while true {
      var pollfdMap: [Int32: pollfd] = [:]
      for socket in ([cancelSocket.outputFD] + readObservedSockets) {
        pollfdMap[socket] = pollfd(fd: socket, events: Int16(POLLIN | POLLPRI), revents: 0)
      }
      for socket in (writeObservedSockets) {
        if var pollFD = pollfdMap[socket] {
          pollFD.events |= Int16(POLLOUT)
          pollfdMap[socket] = pollFD
        } else {
          pollfdMap[socket] = pollfd(fd: socket, events: Int16(POLLOUT), revents: 0)
        }
      }
      var pollfds = [pollfd](pollfdMap.values)
      Log.verbose("waiting on \(pollfds.count - 1) sockets", context: "Poll")
      poll(&pollfds, nfds_t(pollfds.count), -1)
      cancelSocket.reset()
      var socketStates: [Int32: SocketState] = [:]
      for pollSocket in pollfds where pollSocket.fd != cancelSocket.outputFD {
        socketStates[pollSocket.fd] = .idle
        if pollSocket.revents != 0 {
          if pollSocket.revents & Int16(POLLERR | POLLHUP | POLLNVAL) != 0 {
            socketStates[pollSocket.fd] = .closed
            readObservedSockets.remove(pollSocket.fd)
            writeObservedSockets.remove(pollSocket.fd)
          } else if pollSocket.revents & Int16(POLLIN | POLLPRI) != 0 && pollSocket.revents & Int16(POLLOUT) != 0 {
            socketStates[pollSocket.fd] = .readyToReadAndWrite
            readObservedSockets.remove(pollSocket.fd)
            writeObservedSockets.remove(pollSocket.fd)
          } else if pollSocket.revents & Int16(POLLIN | POLLPRI) != 0 {
            socketStates[pollSocket.fd] = .readyToRead
            readObservedSockets.remove(pollSocket.fd)
          } else if pollSocket.revents & Int16(POLLOUT) != 0 {
            socketStates[pollSocket.fd] = .readyToWrite
            writeObservedSockets.remove(pollSocket.fd)
          } else {
            Log.error("Unhandled events \(pollSocket.revents)", context: "Poll")
          }
        }
      }
      if socketStates.contains(where: { $0.value != .idle }) {
        let socketStates = socketStates
        self.stateUpdateListener(socketStates)
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
  
  var pollTask: Task<[Int32: SocketState], any Error>?
  var writeSocketListeners: [Int32: CheckedContinuation<Void, Error>] = [:]
  var readSocketListeners: [Int32: CheckedContinuation<Void, Error>] = [:]
  
  public func pollStateUpdate(_ socketStates: [Int32: SocketState]) async {
    for socketState in socketStates where socketState.value != .idle {
      let readContinuation = readSocketListeners[socketState.key]
      let writeContinuation = writeSocketListeners[socketState.key]
      switch socketState.value {
      case .closed:
        readSocketListeners[socketState.key] = nil
        writeSocketListeners[socketState.key] = nil
        readContinuation?.resume(throwing: SocketError.closed)
        writeContinuation?.resume(throwing: SocketError.closed)
      case .readyToReadAndWrite:
        readSocketListeners[socketState.key] = nil
        writeSocketListeners[socketState.key] = nil
        readContinuation?.resume()
        writeContinuation?.resume()
      case .readyToRead:
        readSocketListeners[socketState.key] = nil
        readContinuation?.resume()
      case .readyToWrite:
        writeSocketListeners[socketState.key] = nil
        writeContinuation?.resume()
      case .idle: continue
      }
    }
  }
  
  func waitUntilReadable(_ socket: Socket) async throws -> Void {
    try await withCheckedThrowingContinuation { continuation in
      addReadListener(continuation, to: socket.socketFileDescriptor)
      poller.update(readObservedSockets: Set(readSocketListeners.keys))
    }
  }
  
  func waitUntilWriteable(_ socket: Socket) async throws -> Void {
    try await withCheckedThrowingContinuation { continuation in
      addWriteListener(continuation, to: socket.socketFileDescriptor)
      poller.update(writeObservedSockets: Set(writeSocketListeners.keys))
    }
  }
  
  private func addReadListener(_ continuation: CheckedContinuation<Void, Error>, to fd: Int32) {
    if let existingContinuation = readSocketListeners[fd] {
      Log.error("Trying to wait for fd that's already been waited for", context: "Poller")
      existingContinuation.resume(throwing: SocketError.closed)
    }
    readSocketListeners[fd] = continuation
  }
  
  private func addWriteListener(_ continuation: CheckedContinuation<Void, Error>, to fd: Int32) {
    if let existingContinuation = writeSocketListeners[fd] {
      Log.error("Trying to wait for fd that's already been waited for", context: "Poller")
      existingContinuation.resume(throwing: SocketError.closed)
    }
    writeSocketListeners[fd] = continuation
  }
}
