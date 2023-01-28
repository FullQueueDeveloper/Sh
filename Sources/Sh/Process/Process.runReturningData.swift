import Foundation

extension Process {
  
  public func runReturningData() throws -> Data {
    
    let queue = DispatchQueue(label: "Sh-standardOutput")
    var data = SafeDataBuffer()
    let pipe = Pipe()
    
    self.standardOutput = pipe
    self.standardError = FileHandle.standardError
    
#if !os(Linux)
    pipe.fileHandleForReading.readabilityHandler = { handler in
      let nextData = handler.availableData
      data.append(nextData)
    }
#endif
    
    try self.run()
    
#if os(Linux)
    queue.sync {
      data = pipe.fileHandleForReading.readDataToEndOfFile()
    }
#endif
    
    self.waitUntilExit()
    
    if let terminationError = terminationError {
      throw terminationError
    } else {
      return data.unsafeData
    }
  }
    
  public func runReturningData() async throws -> Data {   

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
      let dataBuffer = SafeDataBuffer()
      let pipe = Pipe()

      self.standardOutput = pipe
      self.standardError = FileHandle.standardError
      
#if !os(Linux)
      pipe.fileHandleForReading.readabilityHandler = { handler in
        let nextData = handler.availableData
        dataBuffer.append(nextData)
      }
#endif
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
#if os(Linux)
        Task {
          let data = pipe.fileHandleForReading.readDataToEndOfFile()
          await dataHolder.append(data)
        }
#endif
      } catch {
        continuation.resume(with: .failure(error))
      }
    }
  }
}
