// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module cirp

pub fn update_code[T](config GenConfig) !string {
	return error('${@STRUCT}.${@FN}: this function should only be called within a `\$if plugins ? {}` scope')
}
