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
	
	@Option(name: .shortAndLong, help: "Output format (json, binary, text)")
	var format: String = "json"
	
	
	@Option(name: .long, help: "Shader function name")
	var function: String = "compute_main"
	
	@Option(name: .long, help: "Input data type (float32, int32, uint32)")
	var inputType: String = "float32"

	
	func run() throws {
		let executor = try MetalShaderExecutor()
		
		// Load and compile shader
		let shaderSource = try String(contentsOfFile: shaderPath)
		let computeFunction = try executor.compileShader(source: shaderSource, functionName: function)
		
		// Load input data
		let inputData = try loadInputData(from: inputPath, type: inputType)
		
		// Execute shader
		let outputData = try executor.executeShader(
			computeFunction: computeFunction,
			inputData: inputData,
		)
		
		// Output results
		try outputResults(data: outputData, format: format, type: inputType)
	}

	private func loadInputData(from path: String, type: String) throws -> Data {
		let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
		
		switch fileExtension {
		case "txt", "csv", "json":
			return try loadTextData(from: path, type: type)
		default:
			// Try to load as binary data
			return try Data(contentsOf: URL(fileURLWithPath: path))
		}
	}
	
	private func loadTextData(from path: String, type: String) throws -> Data {
		let content = try String(contentsOfFile: path)
		let numbers = content.components(separatedBy: .whitespacesAndNewlines)
			.compactMap { $0.isEmpty ? nil : $0 }
		
		var data = Data()
		
		for numberString in numbers {
			switch type {
			case "float32":
				if let value = Float(numberString) {
					withUnsafeBytes(of: value) { data.append(contentsOf: $0) }
				}
			case "int32":
				if let value = Int32(numberString) {
					withUnsafeBytes(of: value) { data.append(contentsOf: $0) }
				}
			case "uint32":
				if let value = UInt32(numberString) {
					withUnsafeBytes(of: value) { data.append(contentsOf: $0) }
				}
			default:
				throw ValidationError("Unsupported input type: \(type)")
			}
		}
		
		return data
	}
	
	
	private func outputResults(data: Data, format: String, type: String) throws {
		switch format.lowercased() {
		case "json":
			try outputAsJSON(data: data, type: type)
		case "binary":
			try outputAsBinary(data: data)
		case "text":
			try outputAsText(data: data, type: type)
		default:
			throw ValidationError("Unsupported output format: \(format)")
		}
	}
	
	private func outputAsJSON(data: Data, type: String) throws {
		var values: [Any] = []
		
		data.withUnsafeBytes { bytes in
			let buffer = bytes.bindMemory(to: UInt8.self)
			
			switch type {
			case "float32":
				let floatBuffer = bytes.bindMemory(to: Float.self)
				values = Array(floatBuffer)
			case "int32":
				let intBuffer = bytes.bindMemory(to: Int32.self)
				values = Array(intBuffer)
			case "uint32":
				let uintBuffer = bytes.bindMemory(to: UInt32.self)
				values = Array(uintBuffer)
			default:
				values = Array(buffer)
			}
		}
		
		let jsonData = try JSONSerialization.data(withJSONObject: values, options: .prettyPrinted)
		print(String(data: jsonData, encoding: .utf8) ?? "")
	}
	
	private func outputAsBinary(data: Data) throws {
		FileHandle.standardOutput.write(data)
	}
	
	private func outputAsText(data: Data, type: String) throws {
		data.withUnsafeBytes { bytes in
			switch type {
			case "float32":
				let floatBuffer = bytes.bindMemory(to: Float.self)
				for value in floatBuffer {
					print(value)
				}
			case "int32":
				let intBuffer = bytes.bindMemory(to: Int32.self)
				for value in intBuffer {
					print(value)
				}
			case "uint32":
				let uintBuffer = bytes.bindMemory(to: UInt32.self)
				for value in uintBuffer {
					print(value)
				}
			default:
				let buffer = bytes.bindMemory(to: UInt8.self)
				for value in buffer {
					print(value)
				}
			}
		}
	}
}
