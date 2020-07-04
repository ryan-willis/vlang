module runtime

import os

#include <psapi.h>
#flag windows -l psapi

// funcs
fn C.GetCurrentProcessorNumber() u32
fn C.GetProcessMemoryInfo() int

//structs
struct C._PROCESS_MEMORY_COUNTERS {
	WorkingSetSize u32
}

pub fn current_process_mem_usage() u32 {
	usage := C._PROCESS_MEMORY_COUNTERS{}
	if C.GetProcessMemoryInfo(C.GetCurrentProcess(), &usage, sizeof(usage)) != 0 {
		return usage.WorkingSetSize
	}
	return 0
}

fn nr_cpus_win() int {
	mut nr := int(C.GetCurrentProcessorNumber())
	if nr == 0 {
		nr = os.getenv('NUMBER_OF_PROCESSORS').int()
	}
	return nr || 1
}

fn nr_cpus_nix() int {
	panic('cannot call nr_cpus_nix on windows')
}

fn current_process_mem_usage_mac() u32 {
	panic('cannot call current_process_mem_usage_mac on windows')
}