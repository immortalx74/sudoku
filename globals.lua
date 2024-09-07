e_mouse_state = {
	clicked = 1,
	held = 2,
	released = 3
}

e_colors      = {
	bg = { 0.8, 0.8, 0.8 },
	text = { 0.2, 0.28, 0.38 },
	text_wrong = { 0.8, 0.2, 0.2 },
	match = { 0.76, 0.84, 0.92 },
	affected = { 0.89, 0.92, 0.95 },
	highlight = { 0.53, 0.67, 0.78 }
}

cur_cell_idx  = 1
cells         = {}
hidden = {}
window        = { w = 0, h = 0, tex = nil, pass = nil, aspect_multiplier = 1, tex_w = 0, tex_h = 0 }
metrics       = {}
mouse         = { x = 0, y = 0, x_prev = 0, y_prev = 0, button_prev = 0, button_curr = 0, state = e_mouse_state.released }
