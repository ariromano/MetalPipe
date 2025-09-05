import Foundation
import Metal

class MetalShaderExecutor {
	private let device: MTLDevice
	private let commandQueue: MTLCommandQueue
	
	init() throws {
		guard let device = MTLCreateSystemDefaultDevice() else {
			throw MetalPipeError.noMetalDevice
		}
		
		guard let commandQueue = device.makeCommandQueue() else {
			throw MetalPipeError.commandQueueCreationFailed
		}
		
		self.device = device
		self.commandQueue = commandQueue
	}
	
	func compileShader(source: String, functionName: String) throws -> MTLComputePipelineState {
		
		// Create library from source
		let library: MTLLibrary
		do {
			library = try device.makeLibrary(source: source, options: nil)
		} catch {
			throw MetalPipeError.shaderCompilationFailed(error.localizedDescription)
		}
		
		// Get the compute function
		guard let function = library.makeFunction(name: functionName) else {
			throw MetalPipeError.functionNotFound(functionName)
		}
		
		// Create compute pipeline state
		do {
			return try device.makeComputePipelineState(function: function)
		} catch {
			throw MetalPipeError.pipelineStateCreationFailed(error.localizedDescription)
		}
	}
	
	func executeShader(
		computeFunction: MTLComputePipelineState,
		inputData: Data,
		threadGroupSize: MTLSize,
		threadGroups: MTLSize,
		bufferSize: Int? = nil
	) throws -> Data {
		// Determine buffer size
		let actualBufferSize = bufferSize ?? max(inputData.count, 1024)
		
		// Create input buffer
		guard let inputBuffer = device.makeBuffer(bytes: inputData.withUnsafeBytes { $0.baseAddress! }, 
												  length: actualBufferSize, 
												  options: .storageModeShared) else {
			throw MetalPipeError.bufferCreationFailed
		}
		
		// Create output buffer (same size as input for now)
		guard let outputBuffer = device.makeBuffer(length: actualBufferSize, 
												   options: .storageModeShared) else {
			throw MetalPipeError.bufferCreationFailed
		}
		
		// Create command buffer
		guard let commandBuffer = commandQueue.makeCommandBuffer() else {
			throw MetalPipeError.commandBufferCreationFailed
		}
		
		// Create compute encoder
		guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
			throw MetalPipeError.computeEncoderCreationFailed
		}
		
		// Set pipeline state and buffers
		encoder.setComputePipelineState(computeFunction)
		encoder.setBuffer(inputBuffer, offset: 0, index: 0)
		encoder.setBuffer(outputBuffer, offset: 0, index: 1)
		
		// Dispatch threads
		encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
		encoder.endEncoding()
		
		// Commit and wait
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		
		// Check for errors
		if let error = commandBuffer.error {
			throw MetalPipeError.executionFailed(error.localizedDescription)
		}
		
		// Extract output data
		let outputPointer = outputBuffer.contents()
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

enum MetalPipeError: Error {
	case noMetalDevice
	case commandQueueCreationFailed
	case shaderCompilationFailed(String)
	case functionNotFound(String)
	case pipelineStateCreationFailed(String)
	case bufferCreationFailed
	case commandBufferCreationFailed
	case computeEncoderCreationFailed
	case executionFailed(String)
	
	var errorDescription: String? {
		switch self {
		case .noMetalDevice:
			return "No Metal device available"
		case .commandQueueCreationFailed:
			return "Failed to create command queue"
		case .shaderCompilationFailed(let details):
			return "Shader compilation failed: \(details)"
		case .functionNotFound(let name):
			return "Function '\(name)' not found in shader"
		case .pipelineStateCreationFailed(let details):
			return "Pipeline state creation failed: \(details)"
		case .bufferCreationFailed:
			return "Buffer creation failed"
		case .commandBufferCreationFailed:
			return "Command buffer creation failed"
		case .computeEncoderCreationFailed:
			return "Compute encoder creation failed"
		case .executionFailed(let details):
			return "Shader execution failed: \(details)"
		}
	}
}
