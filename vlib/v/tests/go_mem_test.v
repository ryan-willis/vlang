import time
import runtime

fn long_proc(x int, y int) {
	time.sleep_ms(10)
	mut msg := 'done with $y for #$x'
	msg = ''
}

fn test_go_cleanup() {
	mem_begin := runtime.current_process_mem_usage() / 1024
	for x in 1..4 {
		for y in 1..100 {
			go long_proc(x, y)
		}
	}
	mem_during := runtime.current_process_mem_usage() / 1024
	assert mem_during - mem_begin > 0

	time.sleep_ms(20)

	mem_done := runtime.current_process_mem_usage() / 1024
	assert mem_done <= mem_during

	$if !windows {
		// this breaks without thread detaching
		assert mem_begin * 2 > mem_done
	}
}