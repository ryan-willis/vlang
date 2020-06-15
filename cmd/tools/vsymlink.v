import os
import v.pref

fn main(){
	vexe := pref.vexe_path()
	$if windows {
		setup_symlink_windows(vexe)
	} $else {
		setup_symlink(vexe)
	}
}

fn setup_symlink(vexe string) {
	$if !windows {
		link_path := '/usr/local/bin/v'

		// see if it exists already
		if os.exists(link_path) {
			if os.is_dir(link_path) {
				warn_and_exit('Directory exists at "$link_path"')
			}
			mut link_target := vcalloc(os.max_path_len)
			if C.readlink(link_path.str, link_target, os.max_path_len) == -1 {
					warn_and_exit('Failed to create symlink. File exists at "$link_path"')
			}
			else {
				target := os.real_path(string(link_target))
				if target == vexe {
					warn_and_exit('Symlink is already at "$link_path". Give `v version` a try!')
				}
				else {
					warn_and_exit('Another symlink exists at "$link_path" pointing to "$target". Remove it to symlink `v` there.')
				}
			}
		}

		// create it
		os.symlink(vexe, link_path) or {
			// TODO: Detect android and have its own function outside of this?
			// Does it support calling os.symlink (C.symlink)?
			if os.system("uname -o | grep -q \'[A/a]ndroid\'") == 0 {
				println('Failed to create symlink "$link_path". Trying again with Termux path for Android.')
				android_link_path := '/data/data/com.termux/files/usr/bin/v'
				android_ret := os.exec('ln -sf $vexe $link_path') or { panic(err) }
				if android_ret.exit_code == 1 {
					println('Symlink "$android_link_path" has been created')
					exit(0)
					return
				} else {
					warn_and_exit('Failed to create symlink "$android_link_path". Try again with sudo.')
					return
				}
			}
			warn_and_exit('Failed to create symlink "$link_path": ' + err)
			return
		}

		// success
		println('Symlink "$link_path" has been created')
	}
}

fn setup_symlink_windows(vexe string) {
	$if windows {
		// Create a symlink in a new local folder (.\.bin) so we can put it
		// in %PATH% without polluting it with anything else (like make.bat).
		// This will make the `v` available on cmd.exe, PowerShell, and
		// MinGW(MSYS)/WSL/Cygwin

		vdir        := os.real_path(os.dir(vexe))
		vsymlinkdir := os.join_path(vdir, '.bin')
		vsymlink    := os.join_path(vsymlinkdir, 'v.exe')

		if !os.exists(vsymlinkdir) {
			os.mkdir_all(vsymlinkdir) // will panic if fails
		}

		os.rm(vsymlink)

		if os.system('mklink "$vsymlink" "$vexe"') == 0 {
			println('yay?? check it')
			exit(0)
		}
		exit(1)
		os.symlink(vsymlink, vexe) or {
			warn_and_exit('Error creating symlink: ' + err)
		}

		print('Symlink to $vexe created.\nChecking system %PATH%...')

		reg_sys_env_handle  := get_reg_sys_env_handle() or {
			warn_and_exit(err)
			return
		}
		defer {
			C.RegCloseKey(reg_sys_env_handle)
		}

		sys_env_path := get_reg_value(reg_sys_env_handle, 'Path') or {
			warn_and_exit(err)
			return
		}

		current_sys_paths := sys_env_path.split(os.path_delimiter).map(it.trim('/$os.path_separator'))
		mut new_paths := [ vsymlinkdir ]
		for p in current_sys_paths {
			if p !in new_paths {
				new_paths << p
			}
		}

		new_sys_env_path := new_paths.join(';')

		if new_sys_env_path == sys_env_path {
			println('configured.')
		}
		else {
			print('not configured.\nAdding symlink directory to system %PATH%...')
			set_reg_value(reg_sys_env_handle, 'Path', new_sys_env_path) or {
				warn_and_exit(err)
			}
			println('done.')
		}

		print('Letting running processes know to update their environment...')
		send_setting_change_msg('Environment') or {
			eprintln('\n' + err)
			warn_and_exit('You might need to run this again to have the `v` command in your %PATH%')
		}

		println('finished.\n\nNote: restart your shell/IDE to load the new %PATH%.')
		println('After restarting your shell/IDE, give `v version` a try in another dir!')
	}
}

fn warn_and_exit(err string) {
	eprintln(err)
	exit(1)
}

// get the system environment registry handle
fn get_reg_sys_env_handle() ?voidptr {
	$if windows { // wrap for cross-compile compat
		// open the registry key
		reg_key_path := 'SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment'
		reg_env_key  := voidptr(0) // or HKEY (HANDLE)
		if C.RegOpenKeyEx(os.hkey_local_machine, reg_key_path.to_wide(), 0, os.key_query_value | os.key_set_value, &reg_env_key) != 0 {
			return error('Could not open "$reg_key_path" in the registry')
		}
		return reg_env_key
	}
	return error('not on windows')
}

// get a value from a given $key
fn get_reg_value(reg_env_key voidptr, key string) ?string {
	$if windows {
		// query the value (shortcut the sizing step)
		reg_value_size := 4095 // this is the max length (not for the registry, but for the system %PATH%)
		mut reg_value  := &u16(malloc(reg_value_size))
		if C.RegQueryValueEx(reg_env_key, key.to_wide(), 0, 0, reg_value, &reg_value_size) != 0 {
			return error('Unable to get registry value for "$key", are you running as an Administrator?')
		}

		return string_from_wide(reg_value)
	}
	return error('not on windows')
}

// sets the value for the given $key to the given  $value
fn set_reg_value(reg_key voidptr, key string, value string) ?bool {
	$if windows {
		if C.RegSetValueEx(reg_key, key.to_wide(), 0, 1, value.to_wide(), 4095) != 0 {
			return error('Unable to set registry value for "$key", are you running as an Administrator?')
		}

		return true
	}
	return error('not on windows')
}

// Broadcasts a message to all listening windows (explorer.exe in particular)
// letting them know that the system environment has changed and should be reloaded
fn send_setting_change_msg(message_data string) ?bool {
	$if windows {
		if C.SendMessageTimeout(os.hwnd_broadcast, os.wm_settingchange, 0, message_data.to_wide(), os.smto_abortifhung, 5000, 0) == 0 {
			return error('Could not broadcast WM_SETTINGCHANGE')
		}
		return true
	}
	return error('not on windows')
}
