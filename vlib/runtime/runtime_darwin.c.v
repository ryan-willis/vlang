module runtime

#include <mach/task.h>
#include <mach/mach_init.h>

// func
fn C.task_info()
fn C.current_task()

//structs
struct C.task_info_t{}
struct C.task_basic_info{
	resident_size u32
}

pub fn mac_cur_proc_mem_use() u32 {
	usage := C.task_basic_info{}
	tbic := u32(C.TASK_BASIC_INFO_COUNT)
	if C.task_info(C.current_task(), C.TASK_BASIC_INFO, &C.task_info_t(&usage), &tbic) == C.KERN_SUCCESS {
		return usage.resident_size
	}
	return 0 // if above failed
}