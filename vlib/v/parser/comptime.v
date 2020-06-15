// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module parser

import os
import v.ast
import v.pref
import v.vmod
import v.table
import vweb.tmpl

const (
	supported_platforms = ['windows', 'mac', 'macos', 'darwin', 'linux', 'freebsd', 'openbsd',
		'netbsd', 'dragonfly', 'android', 'js', 'solaris', 'haiku', 'linux_or_macos']
)

fn (mut p Parser) resolve_vroot(flag string) string {
	mcache := vmod.get_cache()
	vmod_file_location := mcache.get_by_folder(p.file_name_dir)
	if vmod_file_location.vmod_file.len == 0 {
		// There was no actual v.mod file found.
		p.error('To use @VROOT, you need' + ' to have a "v.mod" file in ${p.file_name_dir},' +
			' or in one of its parent folders.')
	}
	vmod_path := vmod_file_location.vmod_folder
	return flag.replace('@VROOT', os.real_path(vmod_path))
}

// // #include, #flag, #v
fn (mut p Parser) hash() ast.HashStmt {
	mut val := p.tok.lit
	p.next()
	if p.pref.backend == .js {
		if !p.file_name.ends_with('.js.v') {
			p.error('Hash statements are only allowed in backend specific files such "x.js.v"')
		}
		if p.mod == 'main' {
			p.error('Hash statements are not allowed in the main module. Please place them in a separate module.')
		}
	}
	if val.starts_with('include') {
		mut flag := val[8..]
		if flag.contains('@VROOT') {
			vroot := p.resolve_vroot(flag)
			val = 'include $vroot'
		}
	}
	if val.starts_with('flag') {
		// #flag linux -lm
		mut flag := val[5..]
		// expand `@VROOT` to its absolute path
		if flag.contains('@VROOT') {
			flag = p.resolve_vroot(flag)
		}
		for deprecated in ['@VMOD', '@VMODULE', '@VPATH', '@VLIB_PATH'] {
			if flag.contains(deprecated) {
				p.error('${deprecated} had been deprecated, use @VROOT instead.')
			}
		}
		// println('adding flag "$flag"')
		p.table.parse_cflag(flag, p.mod, p.pref.compile_defines_all) or {
			p.error(err)
		}
		/*
		words := val.split(' ')
		if words.len > 1 && words[1] in supported_platforms {
			if p.pref.os == .mac && words[1] == 'darwin' {
				p.pref.cflags += val.after('darwin')
			}
		}
		*/
	}
	return ast.HashStmt{
		val: val
		mod: p.mod
	}
}

fn (mut p Parser) vweb() ast.ComptimeCall {
	p.check(.dollar)
	p.check(.name) // skip `vweb.html()` TODO
	p.check(.dot)
	p.check(.name)
	p.check(.lpar)
	p.check(.rpar)
	// Compile vweb html template to V code, parse that V code and embed the resulting V function
	// that returns an html string.
	html_name := '${p.cur_fn_name}.html'
	// Looking next to the vweb program
	dir := os.dir(p.scanner.file_path)
	mut path := os.join_path(dir, html_name)
	if !os.exists(path) {
		// can be in `templates/`
		path = os.join_path(dir, 'templates', html_name)
		if !os.exists(path) {
			p.error('vweb HTML template "$html_name" not found')
		}
		// println('path is now "$path"')
	}
	// if p.pref.is_verbose {
	println('>>> compiling vweb HTML template "$path"')
	// }
	v_code := tmpl.compile_file(path, p.cur_fn_name)
	mut scope := &ast.Scope{
		start_pos: 0
		parent: p.global_scope
	}
	file := parse_text(v_code, p.table, p.pref, scope, p.global_scope)
	if p.pref.is_verbose {
		println('\n\n')
		println('>>> vweb template for ${path}:')
		println(v_code)
		println('>>> end of vweb template END')
		println('\n\n')
	}
	// copy vars from current fn scope into vweb_tmpl scope
	for stmt in file.stmts {
		if stmt is ast.FnDecl {
			fn_decl := stmt as ast.FnDecl
			if fn_decl.name == 'vweb_tmpl_$p.cur_fn_name' {
				tmpl_scope := file.scope.innermost(fn_decl.body_pos.pos)
				for _, obj in p.scope.objects {
					if obj is ast.Var {
						mut v := obj as ast.Var
						tmpl_scope.register(v.name, *v)
						// TODO: this is yuck, track idents in parser
						// or defer unused var logic to checker
						if v_code.contains(v.name) {
							v.is_used = true
						}
					}
				}
				break
			}
		}
	}
	return ast.ComptimeCall{
		is_vweb: true
		vweb_tmpl: file
	}
}

fn (mut p Parser) comp_if() ast.Stmt {
	pos := p.tok.position()
	p.next()
	// if p.tok.kind == .name && p.tok.lit == 'vweb' {
	// return p.vweb()
	// }
	p.check(.key_if)
	is_not := p.tok.kind == .not
	if is_not {
		p.next()
	}
	val := p.check_name()
	mut stmts := []ast.Stmt{}
	mut skip_os := false
	if val in supported_platforms {
		os := os_from_string(val)
		// `$if os {` for a different target, skip everything inside
		// to avoid compilation errors (like including <windows.h> or calling WinAPI fns
		// on non-Windows systems)
		if !p.pref.is_fmt && ((!is_not && os != p.pref.os) || (is_not && os == p.pref.os)) &&
			!p.pref.output_cross_c {
			skip_os = true
			p.check(.lcbr)
			// p.warn('skipping $if $val os=$os p.pref.os=$p.pref.os')
			mut stack := 1
			for {
				if p.tok.kind == .key_return {
					p.returns = true
				}
				if p.tok.kind == .lcbr {
					stack++
				} else if p.tok.kind == .rcbr {
					stack--
				}
				if p.tok.kind == .eof {
					break
				}
				if stack <= 0 && p.tok.kind == .rcbr {
					// p.warn('exiting $stack')
					p.next()
					break
				}
				p.next()
			}
		}
	}
	mut is_opt := false
	if p.tok.kind == .question {
		p.next()
		is_opt = true
	}
	if !skip_os {
		stmts = p.parse_block()
	}
	mut node := ast.CompIf{
		is_not: is_not
		is_opt: is_opt
		pos: pos
		val: val
		stmts: stmts
	}
	if p.tok.kind == .dollar && p.peek_tok.kind == .key_else {
		p.next()
		p.next()
		node.has_else = true
		node.else_stmts = p.parse_block()
	}
	return node
}

// TODO import warning bug
const (
	todo_delete_me = pref.OS.linux
)

fn os_from_string(os string) pref.OS {
	match os {
		'linux' {
			return .linux
		}
		'windows' {
			return .windows
		}
		'mac' {
			return .mac
		}
		'macos' {
			return .mac
		}
		'freebsd' {
			return .freebsd
		}
		'openbsd' {
			return .openbsd
		}
		'netbsd' {
			return .netbsd
		}
		'dragonfly' {
			return .dragonfly
		}
		'js' {
			return .js
		}
		'solaris' {
			return .solaris
		}
		'android' {
			return .android
		}
		'msvc' {
			// notice that `-os msvc` became `-cc msvc`
			verror('use the flag `-cc msvc` to build using msvc')
		}
		'haiku' {
			return .haiku
		}
		'linux_or_macos' {
			return .linux
		}
		else {
			panic('bad os $os')
		}
	}
	// println('bad os $os') // todo panic?
	return .linux
}

// `app.$action()` (`action` is a string)
// `typ` is `App` in this example
// fn (mut p Parser) comptime_method_call(typ table.Type) ast.ComptimeCall {
fn (mut p Parser) comptime_method_call(left ast.Expr) ast.ComptimeCall {
	p.check(.dollar)
	method_name := p.check_name()
	/*
	mut j := 0
	sym := p.table.get_type_symbol(typ)
	if sym.kind != .struct_ {
		p.error('not a struct')
	}
	// info := sym.info as table.Struct
	for method in sym.methods {
		if method.return_type != table.void_type {
			continue
		}
		/*
		receiver := method.args[0]
		if !p.expr_var.ptr {
			p.error('`$p.expr_var.name` needs to be a reference')
		}
		amp := if receiver.is_mut && !p.expr_var.ptr { '&' } else { '' }
		if j > 0 {
			p.gen(' else ')
		}
		p.genln('if (string_eq($method_name, _STR("$method.name")) ) ' + '${typ.name}_$method.name ($amp $p.expr_var.name);')
		*/
		j++
	}
	*/
	p.check(.lpar)
	p.check(.rpar)
	if p.tok.kind == .key_orelse {
		p.check(.key_orelse)
		// p.genln('else {')
		p.check(.lcbr)
		// p.statements()
	}
	return ast.ComptimeCall{
		left: left
		method_name: method_name
	}
}
