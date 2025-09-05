# MetalPipe

A macOS command-line application for executing Metal compute shaders.

## Prerequisites

- macOS 10.15
- Xcode Command Line Tools

## Usage

### Syntax

```bash
metalpipe <shader_path> <input_path> [options]
```

### Command Line Options

- `--format, -f`: Output format (json, binary, text) [default: json]
- `--thread-group-size, -t`: Thread group size (e.g., "32,1,1") [default: "32,1,1"]
- `--thread-groups, -g`: Number of thread groups (e.g., "1,1,1") [default: "1,1,1"]
- `--function`: Shader function name [default: "compute_main"]
- `--input-type`: Input data type (float32, int32, uint32) [default: "float32"]
- `--buffer-size`: Buffer size in bytes

## Dependencies

[Swift Argument Parser](https://github.com/apple/swift-argument-parser)
