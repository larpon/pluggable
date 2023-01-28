// NOTE This file is auto-generated.
// Do not tinker with it unless you know what you are doing.
module main

import moo

struct Plugins {
}

fn (mut p Plugins) init(state &State) ! {
}

fn (mut p Plugins) shutdown() ! {}

fn (mut p Plugins) use_moo_state(ms &moo.State) ! {}

fn (mut p Plugins) modify_moo_state(mut ms moo.State) ! {}

fn (mut p Plugins) do_x() ! {}

fn (mut p Plugins) do_y() ! {}

fn (mut p Plugins) do_z() ! {}
