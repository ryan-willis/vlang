module os

fn C._fileno(int) int
fn C._get_osfhandle(fd int) C.intptr_t
fn C.CreateFile() voidptr
fn C.CreateFileW(lpFilename &u16, dwDesiredAccess u32, dwShareMode u32, lpSecurityAttributes &u16, dwCreationDisposition u32, dwFlagsAndAttributes u32, hTemplateFile voidptr) u32
fn C.CreatePipe(hReadPipe &voidptr, hWritePipe &voidptr, lPipeAttributes C.LPSECURITY_ATTRIBUTES, nSize u32) bool
fn C.CreateSymbolicLink() int
fn C.CreateSymbolicLinkW(lpSymlinkFileName &u16, lpTargetFileName &u16, dwFlags u32) u16
fn C.ExpandEnvironmentStrings() int
fn C.ExpandEnvironmentStringsW(lpSrc &u16, lpDst &u16, nSize u32) u32
fn C.GetFinalPathNameByHandle() int
fn C.GetFinalPathNameByHandleW(hFile voidptr, lpFilePath &u16, nSize u32, dwFlags u32) u32
fn C.GetModuleFileName() int
fn C.GetModuleFileNameW(hModule voidptr, lpFilename &u16, nSize u32) u32
fn C.SetHandleInformation(hObject voidptr, dwMask u32, dwFlags u32) bool
fn C.SendMessageTimeout() u32
fn C.SendMessageTimeoutW(hWnd voidptr, Msg u32, wParam &u16, lParam &u16, fuFlags u32, uTimeout u32, lpdwResult &u32) u32
fn C.CreateProcessW(lpApplicationName &u16, lpCommandLine &u16, lpProcessAttributes C.LPSECURITY_ATTRIBUTES, lpThreadAttributes C.LPSECURITY_ATTRIBUTES, bInheritHandles bool, dwCreationFlags u32, lpEnvironment voidptr, lpCurrentDirectory &u16, lpStartupInfo C.LPSTARTUPINFOW, lpProcessInformation C.LPPROCESS_INFORMATION) bool


