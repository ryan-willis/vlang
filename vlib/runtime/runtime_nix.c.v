module runtime

// funcs
fn C.getpagesize() int
fn C.sysconf() int
fn C.fscanf() int

pub fn nr_cpus_nix() int {
	$if linux {
		return C.sysconf(C._SC_NPROCESSORS_ONLN)
	}
	$if macos {
		return C.sysconf(C._SC_NPROCESSORS_ONLN)
	}
	$if solaris {
		return C.sysconf(C._SC_NPROCESSORS_ONLN)
	}
	return 1
}

pub fn current_process_mem_usage() u32 {
	$if macos {
		return current_process_mem_usage_mac()
	}
	self_stat := C.fopen('/proc/self/statm', 'r')
	if self_stat != C.NULL {
		defer {
			C.fclose(self_stat)
		}
		mem := u32(0)
		if C.fscanf(self_stat, '%ul', &mem) == 1 {
			return (mem * u32(C.getpagesize()))
		}
	}
	return 0
}

// cross-compat stubs
fn nr_cpus_win() int {
	panic('cannot call nr_cpus_win on *nix')
}