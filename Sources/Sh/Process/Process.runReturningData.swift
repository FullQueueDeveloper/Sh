import Foundation

extension Process {
  
  public func runReturningData() throws -> Data {
    
    let data = SynchronizedBuffer<Data>()
    let pipe = Pipe()
    
    self.standardOutput = pipe
    self.standardError = FileHandle.standardError
    
    pipe.fileHandleForReading.readabilityHandler = { handler in
      let nextData = handler.availableData
      data.append(nextData)
    }
    
    try self.run()
    
    self.waitUntilExit()
    
    if let terminationError = terminationError {
      throw terminationError
    } else {
      return data.unsafeValue
    }
  }
    
  public func runReturningData() async throws -> Data {   
    self.standardError = FileHandle.standardError
    
    let dataBuffer = SynchronizedBuffer<Data>()
    let pipe = Pipe()
    self.standardOutput = pipe
    pipe.fileHandleForReading.readabilityHandler = { handler in
      let nextData = handler.availableData
      dataBuffer.append(nextData)
    }
    
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
      self.terminationHandler = { process in
        
        if let terminationError = process.terminationError {
          continuation.resume(throwing: terminationError)
        } else {
          Task {
            let data = await dataBuffer.getData()
            continuation.resume(returning: data)
          }
        }
      }
      
      do {
        try self.run()
      } catch {
        continuation.resume(with: .failure(error))
      }
    }
  }
}
