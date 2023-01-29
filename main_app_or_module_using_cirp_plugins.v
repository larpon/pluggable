// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import moo // just to test modifying things from other modules. See ./modules/moo
import cirp // the boilerplate/reflection code implementation. See ./modules/cirp

[heap]
struct State {
mut:
	goo string = 'goo'
}

fn handle_cirp() ! {
	$if cirp_make ? || cirp_template ? || cirp_enable ? || cirp_disable ? || cirp_api ? {
		output := os.join_path(os.dir(@FILE), 'plugins.auto.v')
		hooks := [
			cirp.hook('shutdown', []),
			cirp.hook('use_moo_state', ['moo'], cirp.arg[&moo.State]('ms', false)),
			cirp.hook('modify_moo_state', ['moo'], cirp.arg[moo.State]('ms', true)),
			'do_x',
			'do_y',
			cirp.hook('do_z', []),
		]

		// Generates a template for user facing plugin code.
		$if cirp_template ? {
			tmpl := cirp.template_code[&State](
				mod: @MOD
				hooks: hooks
			)!
			println('${tmpl}')
			exit(0)
		}

		$if cirp_api ? {
			api := cirp.api[&State](
				mod: @MOD
				hooks: hooks
			)!
			mut hook_names := '\tinit() !\n' // init is implicit
			for hook in api.hooks {
				hook_names += '\t${hook.gen_signature()} !\n'
			}
			println('Module: ${api.mod}')
			println('Hooks:\n${hook_names}')
			exit(0)
		}

		$if cirp_disable ? {
			os.rm(output) or {}
			path := os.dir(output)
			if os.is_dir(path) {
				mut files := os.ls(path) or { []string{} }
				for file in files {
					e := os.join_path(path, file)
					if os.is_file(e) {
						if e.ends_with('plugin.v') {
							to := e.all_before_last('.plugin.v') + '.v.plugin'
							os.rename(e, to) or { panic(err) }
							eprintln('Disabled ${os.file_name(e)}')
						}
					}
				}
			}
			eprintln('Run `v -d cirp_make run .`')
		}

		$if cirp_enable ? {
			os.rm(output) or {}
			path := os.dir(output)
			if os.is_dir(path) {
				mut files := os.ls(path) or { []string{} }
				for file in files {
					e := os.join_path(path, file)
					if os.is_file(e) {
						if e.ends_with('.v.plugin') {
							to := e.all_before_last('.v.plugin') + '.plugin.v'
							os.rename(e, to) or { panic(err) }
							eprintln('Enabled ${os.file_name(to)}')
						}
					}
				}
			}
			eprintln('Run `v -d cirp_make run .`')
		}

		// Generates boilerplate plugin code.
		$if cirp_make ? {
			os.rm(output) or {}
			code := cirp.make_code[&State](
				mod: @MOD
				hooks: hooks
			)!
			os.write_file('${output}', code)!
			eprintln('Generated ${output}')
			// eprintln('Code:\n${code}')
		}
	}
}

fn main() {
	state := &State{}

	handle_cirp()!

	$if no_cirp ? {
		eprintln('Plugins not called')
	}

	// Guards against compile errors if the auto generated files
	// are deleted and/or we want to re-build the boilerplate code.
	// TODO this could be prettier.
	$if !no_cirp ? && !cirp_make ? && !cirp_disable ? && !cirp_enable ? {
		mut plugins := &Plugins{}

		mut ms := moo.State{}

		plugins.init(state)!
		// eprintln('State:\n${state}')

		plugins.do_x()!
		// eprintln('State:\n${state}')

		plugins.do_y()!
		// eprintln('State:\n${state}')

		plugins.use_moo_state(ms)!
		// eprintln('moo.State:\n${ms}')
		plugins.modify_moo_state(mut ms)!
		// eprintln('moo.State:\n${ms}')

		plugins.shutdown()!
		// eprintln('State:\n${state}')
	}
}
