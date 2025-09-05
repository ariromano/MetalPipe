#include <metal_stdlib>
using namespace metal;

// Simple compute shader that multiplies each element by 2
kernel void compute_main(device const float* input [[buffer(0)]], device float* output [[buffer(1)]], uint index [[thread_position_in_grid]])
{
	output[index] = input[index] * 2.0;
}
