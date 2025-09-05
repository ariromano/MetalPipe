import Foundation
import Metal
import ArgumentParser

@main
struct MetalPipe: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "metalpipe",
		abstract: "Execute Metal compute shaders from the command line"
	)
	
	@Argument(help: "Path to the Metal shader source file (.metal)")
	var shaderPath: String
	
	@Argument(help: "Path to the input data file")
	var inputPath: String
	
	@Option(name: .shortAndLong, help: "Output format (binary, text)")
	var format: String = "text"
	
	
	@Option(name: .long, help: "Shader function name")
	var function: String = "compute_main"
	
	
	func run() throws {
		let executor = try MetalShaderExecutor()
		
		// Load and compile shader
		let shaderSource = try String(contentsOfFile: shaderPath)
		let computeFunction = try executor.compileShader(source: shaderSource, functionName: function)
		
		// Load input data
		let inputData = try loadInputData(from: inputPath)
		
		// Execute shader
		let outputData = try executor.executeShader(
			computeFunction: computeFunction,
			inputData: inputData,
		)
		
		// Output results
		try outputResults(data: outputData, format: format)
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
	
	
	private func outputResults(data: Data, format: String) throws {
		switch format.lowercased() {
		case "binary":
			try outputAsBinary(data: data)
		case "text":
			try outputAsText(data: data)
		default:
			throw ValidationError("Unsupported output format: \(format)")
		}
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
