// NOTE This file is auto-generated.
// Do not tinker with it unless you know what you are doing.
module main

import moo

struct Plugins {
mut:
	bar &Bar = unsafe { nil }
	foo &Foo = unsafe { nil }
}

fn (mut p Plugins) init(state &State) ! {
	$if !no_cirp ? && !cirp_make ? {
		p.bar = new_plugin_bar(state)
		assert !isnil(p.bar)

		p.foo = new_plugin_foo(state)
		assert !isnil(p.foo)
		p.foo.init()!
	}
}

fn (mut p Plugins) do_y() ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.bar)
		p.bar.do_y()!
	}
}

fn (mut p Plugins) do_z() ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.bar)
		p.bar.do_z()!
	}
}

fn (mut p Plugins) shutdown() ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.bar)
		p.bar.shutdown()!
	}
}

fn (mut p Plugins) use_moo_state(ms &moo.State) ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.bar)
		p.bar.use_moo_state(ms)!
	}
}

fn (mut p Plugins) modify_moo_state(mut ms moo.State) ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.foo)
		p.foo.modify_moo_state(mut ms)!
	}
}

fn (mut p Plugins) do_x() ! {
	$if !no_cirp ? && !cirp_make ? {
		assert !isnil(p.foo)
		p.foo.do_x()!
	}
}

