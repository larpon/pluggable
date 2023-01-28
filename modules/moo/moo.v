// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module moo

[heap]
pub struct State {
pub mut:
	moo string = 'moo'
}

pub fn (s State) abc() string {
	return 'abc'
}
