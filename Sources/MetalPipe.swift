import Foundation
import Metal
import ArgumentParser

@main
struct MetalPipe: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "metalpipe",
		abstract: "Execute Metal compute shaders from the command line"
	)
	
	@Argument(help: "Path to the shader source")
	var shaderPath: String
	
	@Argument(help: "Path to input data")
	var inputPath: String
 
	func run() throws {
		let executor = try MetalShaderExecutor()
		
		// Load and compile shader
		let shaderSource = try String(contentsOfFile: shaderPath)
		let computeFunction = try executor.compileShader(source: shaderSource, functionName: "compute_main")
		
		// Load input data
		let inputData = try loadInputData(from: inputPath)
		
		// Execute shader
		let outputData = try executor.executeShader(
			computeFunction: computeFunction,
			inputData: inputData,
		)
		
		// Output results
		try outputResults(data: outputData)
	}

	private func loadInputData(from path: String) throws -> Data {
		let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
		
		switch fileExtension {
		case "txt", "csv":
			return try loadTextData(from: path)
		default:
			// Try to load as binary data
			return try Data(contentsOf: URL(fileURLWithPath: path))
		}
	}
	
	private func loadTextData(from path: String) throws -> Data {
		let content = try String(contentsOfFile: path)
		let numbers = content.components(separatedBy: .whitespacesAndNewlines)
			.compactMap { $0.isEmpty ? nil : $0 }
		
		var data = Data()
		
		for numberString in numbers {
				if let value = Float(numberString) {
					withUnsafeBytes(of: value) { data.append(contentsOf: $0) }
				}
		}
		
		return data
	}
	
	
	private func outputResults(data: Data) throws {
		try outputAsText(data: data)

	}
	
	private func outputAsBinary(data: Data) throws {
		FileHandle.standardOutput.write(data)
	}
	
	private func outputAsText(data: Data) throws {
		data.withUnsafeBytes { bytes in
				let floatBuffer = bytes.bindMemory(to: Float.self)
				for value in floatBuffer {
					print(value)
				}
		}
	}
}
