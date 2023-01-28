// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module cirp

import v.reflection

pub fn make_code[T](config MakeConfig) !string {
	/*$if T is $Struct {
	} $else {
		$compile_error('update_code only support struct contexts')
	}*/
	state_struct := T.name
	wrapper_struct := config.wrap_struct
	is_valid_struct_name(wrapper_struct)!
	receiver := gen_receiver_var_name(wrapper_struct)
	mut hooks := config.hooks.clone()

	mut mod := config.mod
	mut struct_code := ''
	mut init_code := ''
	mut custom_code := map[string]string{}

	funcs := reflection.get_funcs()
	register_funcs := funcs.filter(it.name.starts_with('new_plugin_'))

	mut active_plugin_structs := []string{}
	for func in register_funcs {
		active_plugin_structs << reflection.type_name(func.return_typ)
	}

	init_hooks := funcs.filter(fn [active_plugin_structs] (f reflection.Function) bool {
		if rt := reflection.get_type(f.receiver_typ) {
			return f.name == 'init' && rt.name in active_plugin_structs
		}
		return false
	})

	mut custom_hooks := funcs.filter(fn [hooks, active_plugin_structs] (f reflection.Function) bool {
		if rt := reflection.get_type(f.receiver_typ) {
			if rt.name in active_plugin_structs {
				if _ := hooks.find_fn(f.name) {
					return true
				}
			}
		}
		return false
	})

	mut imports := ''
	for imp in hooks.imports() {
		imports += 'import ${imp}\n'
	}
	imports = imports.trim('\n')

	for func in register_funcs {
		member_field := func.name.all_after('new_plugin_')

		plugin_struct := reflection.type_name(func.return_typ)

		struct_code += '\t${member_field} &${plugin_struct} = unsafe { nil }'

		init_code += '\t\t${receiver}.${member_field} = ${func.name}(state)\n'
		init_code += '\t\tassert !isnil(${receiver}.${member_field})\n'

		for method in init_hooks {
			if rt := reflection.get_type(method.receiver_typ) {
				if rt.name == plugin_struct {
					init_code += '\t\t${receiver}.${member_field}.init()!'
				}
			}
		}

		for method in custom_hooks {
			if rt := reflection.get_type(method.receiver_typ) {
				if rt.name == plugin_struct {
					custom_code[method.name] += '\t\tassert !isnil(${receiver}.${member_field})\n'
					if hook := hooks.find_fn(method.name) {
						custom_code[method.name] += '\t\t${receiver}.${member_field}.${hook.gen_call_signature()}!'
					}
				}
			}
		}

		for method in custom_hooks {
			custom_code[method.name] += '\n'
		}

		if struct_code != '' {
			struct_code += '\n'
		}
		if init_code != '' {
			init_code += '\n'
		}
	}

	mut v_source := '// NOTE This file is auto-generated.
// Do not tinker with it unless you know what you are doing.
module ${mod}

${imports}\n
'

	if struct_code != '' {
		struct_code = 'mut:\n' + struct_code
	}

	if init_code != '' {
		init_code = '\t' + '$' + 'if !no_cirp ? && !cirp_make ? {\n' + init_code + '\t}\n'
	}

	v_source += 'struct ${wrapper_struct} {\n' + struct_code + '}\n'
	v_source += '\n'
	v_source += 'fn (mut ${receiver} ${wrapper_struct}) init(state ${state_struct}) ! {\n' +
		init_code + '}\n'
	v_source += '\n'
	if custom_code.len > 0 {
		mut generated := []string{}
		for method, code in custom_code {
			method_code := '\t' + '$' + 'if !no_cirp ? && !cirp_make ? {\n' + code.trim(' \n') +
				'\n\t}\n'
			generated << method
			if hook := hooks.find_fn(method) {
				v_source +=
					'fn (mut ${receiver} ${wrapper_struct}) ${hook.gen_signature()} ! {\n' +
					method_code + '}\n'
			}
			v_source += '\n'
		}
		if generated.len < hooks.len {
			// Create stubs
			for hook in hooks {
				if hook.name() !in generated {
					v_source += 'fn (mut ${receiver} ${wrapper_struct}) ${hook.gen_signature()} ! {}\n'
					v_source += '\n'
				}
			}
		}
	} else {
		// Create stubs
		for hook in hooks {
			v_source += 'fn (mut ${receiver} ${wrapper_struct}) ${hook.gen_signature()} ! {}\n'
			v_source += '\n'
		}
	}

	return v_source
}
