import Foundation
import Metal

class MetalShaderExecutor {
	private let device: MTLDevice
	private let commandQueue: MTLCommandQueue
	
	init() throws {
		device = MTLCreateSystemDefaultDevice()!
		
		let commandQueue = device.makeCommandQueue()
		

		self.commandQueue = commandQueue!
	}
	
	func compileShader(source: String, functionName: String) throws -> MTLComputePipelineState {
		
		// Create library from source
		let library: MTLLibrary
		library = try device.makeLibrary(source: source, options: nil)
		
		// Get the compute function
		let function = library.makeFunction(name: functionName)
		
		// Create compute pipeline state

		return try device.makeComputePipelineState(function: function!)
	}
	
	func executeShader(
		computeFunction: MTLComputePipelineState,
		inputData: Data,
		bufferSize: Int? = nil
	) throws -> Data {
		// Determine buffer size
		let actualBufferSize = bufferSize ?? max(inputData.count, 1024)
		
		// Create input buffer
		let inputBuffer = device.makeBuffer(bytes: inputData.withUnsafeBytes { $0.baseAddress! }, length: actualBufferSize, options: .storageModeShared)
		
		// Create output buffer (same size as input for now)
		let outputBuffer = device.makeBuffer(length: actualBufferSize, options: .storageModeShared)
		
		// Create command buffer
		let commandBuffer = commandQueue.makeCommandBuffer()
		
		// Create compute encoder
		let encoder = commandBuffer!.makeComputeCommandEncoder()
		
		// Set pipeline state and buffers
		encoder!.setComputePipelineState(computeFunction)
		encoder!.setBuffer(inputBuffer, offset: 0, index: 0)
		encoder!.setBuffer(outputBuffer, offset: 0, index: 1)
		
		// Dispatch threads
		encoder!.dispatchThreadgroups(MTLSize(width: 32, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
		encoder!.endEncoding()
		
		// Commit and wait
		commandBuffer!.commit()
		commandBuffer!.waitUntilCompleted()
		
		// Extract output data
		let outputPointer = outputBuffer!.contents()
		return Data(bytes: outputPointer, count: actualBufferSize)
	}
	
	func createBuffer(from data: Data, options: MTLResourceOptions = .storageModeShared) -> MTLBuffer? {
		return data.withUnsafeBytes { bytes in
			return device.makeBuffer(bytes: bytes.baseAddress!, length: data.count, options: options)
		}
	}
	
	func createBuffer(length: Int, options: MTLResourceOptions = .storageModeShared) -> MTLBuffer? {
		return device.makeBuffer(length: length, options: options)
	}
}
