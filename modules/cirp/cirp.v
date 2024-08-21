// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module cirp

// NOTE do not import v.reflection in this code this is what the
// `cirp_d_cirp_make.v`/`cirp_notd_cirp_make.v` files are for to
// avoid the host application importing a lot of the extra code
// needed for the reflection to work.
import strconv

@[params]
pub struct MakeConfig {
	mod         string = 'main'
	wrap_struct string = 'Plugins'
	hooks       []Hook
}

@[params]
pub struct TemplateConfig {
	mod           string = 'main'
	plugin_struct string = 'FooPlugin'
	hooks         []Hook
}

@[params]
pub struct APIConfig {
	mod           string = 'main'
	plugin_struct string = 'FooPlugin'
	hooks         []Hook
}

pub type Hook = HookFn | string

pub fn (h Hook) name() string {
	return match h {
		string {
			'${h}'
		}
		HookFn {
			'${h.name}'
		}
	}
}

pub fn (h Hook) gen_signature() string {
	mut sig := ''
	match h {
		string {
			sig = '${h}()'
		}
		HookFn {
			sig = '${h.name}('
			for arg in h.args {
				mut_ := if arg.is_mut { 'mut ' } else { '' }
				sig += '${mut_}${arg.name} ${arg.kind},'
			}
			sig = sig.trim(',')
			sig += ')'
		}
	}
	return sig
}

pub fn (h Hook) gen_call_signature() string {
	mut sig := ''
	match h {
		string {
			sig = '${h}()'
		}
		HookFn {
			sig = '${h.name}('
			for arg in h.args {
				mut_ := if arg.is_mut { 'mut ' } else { '' }
				sig += '${mut_}${arg.name},'
			}
			sig = sig.trim(',')
			sig += ')'
		}
	}
	return sig
}

pub fn (h Hook) imports() []string {
	return match h {
		string {
			[]string{}
		}
		HookFn {
			h.imports
		}
	}
}

struct HookFn {
	name    string
	imports []string
	args    []HookArg
}

pub struct HookArg {
	name   string
	kind   string
	is_mut bool
}

pub fn (h []Hook) find_fn(name string) ?Hook {
	for hook in h {
		match hook {
			string {
				if hook == name {
					return hook
				}
			}
			HookFn {
				if hook.name == name {
					return hook
				}
			}
		}
	}
	return none
}

pub fn (h []Hook) imports() []string {
	mut imports := []string{}
	for hook in h {
		match hook {
			HookFn {
				for imp in hook.imports {
					if imp !in imports {
						imports << imp
					}
				}
			}
			else {}
		}
	}
	return imports
}

pub fn hook(fn_name string, imports []string, hook_args ...HookArg) Hook {
	return Hook(HookFn{
		name:    fn_name
		imports: imports
		args:    hook_args
	})
}

pub fn arg[T](name string, is_mut bool) HookArg {
	return HookArg{
		name:   name
		kind:   T.name
		is_mut: is_mut
	}
}

fn is_valid_struct_name(name string) ! {
	if name == '' {
		return error('${@STRUCT}.${@FN}: name is empty')
	}
	if !name[0].is_capital() {
		return error('${@STRUCT}.${@FN}: name "${name}" is invalid, it must start with a captial letter')
	}
}

fn gen_receiver_var_name(struct_name string) string {
	mut var_name := ''
	for b in struct_name {
		if b.is_capital() {
			var_name += '${strconv.byte_to_lower(b).ascii_str()}'
		}
	}
	return var_name
}

fn gen_lowercase_struct_name(struct_name string) string {
	mut name := ''
	for i, b in struct_name {
		if b.is_capital() {
			if i != 0 && i != struct_name.len - 1 {
				if i + 1 < struct_name.len && !struct_name[i + 1].is_capital() {
					name += '_'
				}
			}
			name += '${strconv.byte_to_lower(b).ascii_str()}'
		} else {
			name += '${b.ascii_str()}'
		}
	}
	return name
}

pub fn template_code[T](config TemplateConfig) !string {
	/*$if T is $Struct {
	} $else {
		$compile_error('template_code only support struct contexts')
	}*/
	state_struct := T.name
	mut mod := config.mod
	struct_name := config.plugin_struct
	is_valid_struct_name(struct_name)!
	receiver := gen_receiver_var_name(struct_name)
	struct_name_lower := gen_lowercase_struct_name(struct_name)
	struct_fn := '$' + '{' + '@' + 'STRUCT}.$' + '{' + '@' + 'FN' + '}'

	mut imports := ''
	for imp in config.hooks.imports() {
		imports += 'import ${imp} // Can be removed if not used by any hooks\n'
	}
	imports = imports.trim('\n')

	mut v_source := '// This is a plugin file template for implementing hooks
// for modifying `${state_struct}` (or internal plugin data) in module `${mod}`.
//
// All methods on `${struct_name}` in this file are optional. They do not have
// to be implemented. Method stubs are meant to serve as an overview of what hooks
// the calling module (in this case "${mod}") exposes.
//
// The bare basics needed for a plugin to work is:
// 1. A function whos name starts with `new_plugin_`, for example: `new_plugin_my_plug`.
// 2. A struct, for example: `struct MyPlug {}`
//
// The `new_plugin_XXX`function must return a (heap!) reference to the struct, for example: `return &MyPlug{}`.
// Storing the reference to `${state_struct}` in as a field on `struct MyPlug {}` is not necessary, but
// usually desired - all depending on what the plugin is designed to do.
//
module ${mod}

${imports}

fn new_plugin_${struct_name_lower}(context ${state_struct}) &${struct_name} {
	return &${struct_name}{
		context: context
	}
}

struct ${struct_name} {
mut:
	context ${state_struct} // Optional context
	// + (optional) local fields, for example:
	// counter int
}

// Optional hooks are printed below.
// Method signatures must be preserved as-is.

fn (mut ${receiver} ${struct_name}) init() ! {
	eprintln(\'${struct_fn} called\')
}\n
' // Create stubs

	for hook in config.hooks {
		v_source += 'fn (mut ${receiver} ${struct_name}) ${hook.gen_signature()} ! {
	eprintln(\'${struct_fn} called\')
	// ${receiver}.context.field = XXX // Optionally modify context
}\n
'
	}
	return v_source
}

pub struct API {
pub:
	mod           string
	imports       []string
	hooks         []Hook
	state_struct  string
	plugin_struct string
}

pub fn api[T](config APIConfig) !API {
	/*$if T is $Struct {
	} $else {
		$compile_error('template_code only support struct contexts')
	}*/
	state_struct := T.name
	plugin_struct_name := config.plugin_struct
	is_valid_struct_name(plugin_struct_name)!

	mut api := API{
		mod:           config.mod
		imports:       config.hooks.imports()
		hooks:         config.hooks
		state_struct:  state_struct
		plugin_struct: plugin_struct_name
	}
	return api
}
