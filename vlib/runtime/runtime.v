// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

module runtime

import os

pub fn nr_cpus() int {
	$if windows {
		return nr_cpus_win()
	}
	return nr_cpus_nix()
}

pub fn nr_jobs() int {
	mut jobs := nr_cpus()
	// allow for overrides, for example using `VJOBS=32 ./v test .`
	vjobs := os.getenv('VJOBS').int()
	if vjobs > 0 {
		jobs = vjobs
	}
	return jobs
}

pub fn is_32bit() bool {
	mut x := false
	$if x32 { x = true }
	return x
}

pub fn is_64bit() bool {
	mut x := false
	$if x64 { x = true }
	return x
}

pub fn is_little_endian() bool {
	mut x := false
	$if little_endian { x = true }
	return x
}

pub fn is_big_endian() bool {
	mut x := false
	$if big_endian { x = true }
	return x
}