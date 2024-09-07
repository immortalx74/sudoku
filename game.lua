require "globals"
require "generator"

local Game = {}


local function UpdateMetrics()
	metrics.text_scale = 0.08 * window.tex_w
	metrics.grid_size = 0.85 * window.tex_w
	metrics.msg_top = 0.035 * window.tex_h
end

local function WindowWasResized()
	local w, h = lovr.system.getWindowDimensions()
	if w ~= window.w or h ~= window.h then
		window.w = w
		window.h = h
		window.tex_w = w
		window.tex_h = h

		-- Do aspect correction
		if (window.w / window.h) > window.aspect_multiplier then
			window.tex_h = window.h
			window.tex_w = window.h * window.aspect_multiplier
		elseif (window.w / window.h) < window.aspect_multiplier then
			window.tex_w = window.w
			window.tex_h = window.w / window.aspect_multiplier
		end

		UpdateMetrics()

		-- Re-generate game texture/pass
		window.tex = lovr.graphics.newTexture( window.tex_w, window.tex_h )
		window.pass = lovr.graphics.newPass( window.tex )

		return true
	end

	return false
end

local function IndexToCoords( index )
	local row = math.floor( (index - 1) / 9 ) + 1
	local col = ((index - 1) % 9) + 1

	return row, col
end

local function CoordsToIndex( row, col )
	return (row - 1) * 9 + col
end

local function IndexToBlock( index )
	local row, col = IndexToCoords( index )

	local block_row = math.floor( (row - 1) / 3 ) + 1
	local block_col = math.floor( (col - 1) / 3 ) + 1

	local block_index = (block_row - 1) * 3 + block_col

	return block_index
end

local function SetWrong()
	for i, v in ipairs( cells ) do
		if v.num and v.editable then
			local row, col = IndexToCoords( i )
			for j, k in ipairs( hidden ) do
				if row == k.row and col == k.col then
					if v.num == k.num then
						v.text_color = e_colors.text
					else
						v.text_color = e_colors.text_wrong
					end
				end
			end
		end
	end
end

local function SetAffected()
	local cur_row, cur_col = IndexToCoords( cur_cell_idx )
	local cur_block_index = IndexToBlock( cur_cell_idx )

	for i, v in ipairs( cells ) do
		local row, col = IndexToCoords( i )
		local block_index = IndexToBlock( i )

		if row == cur_row or col == cur_col or block_index == cur_block_index then
			v.color = e_colors.affected
		else
			v.color = nil
		end

		if row == cur_row and col == cur_col then
			v.color = e_colors.highlight
		end
	end
end

local function SetMatched()
	for i, v in ipairs( cells ) do
		if i ~= cur_cell_idx and v.num and v.num == cells[ cur_cell_idx ].num then
			v.color = e_colors.match
		end
	end
end

local function DrawGrid()
	window.pass:setColor( 0, 0, 0 )
	local left      = (window.tex_w / 2) - (metrics.grid_size / 2)
	local top       = (window.tex_h / 2) - (metrics.grid_size / 2)
	local cell_size = metrics.grid_size / 9

	for i = 1, 10 do
		window.pass:line( left, top, 0, left + metrics.grid_size, top, 0 )
		if (i - 1) % 3 == 0 then
			window.pass:line( left, top - 1, 0, left + metrics.grid_size, top - 1, 0 )
			window.pass:line( left, top + 1, 0, left + metrics.grid_size, top + 1, 0 )
		end
		top = top + cell_size
	end

	left = (window.tex_w / 2) - (metrics.grid_size / 2)
	top  = (window.tex_h / 2) - (metrics.grid_size / 2)

	for i = 1, 10 do
		window.pass:line( left, top, 0, left, top + metrics.grid_size, 0 )
		if (i - 1) % 3 == 0 then
			window.pass:line( left - 1, top, 0, left - 1, top + metrics.grid_size, 0 )
			window.pass:line( left + 1, top, 0, left + 1, top + metrics.grid_size, 0 )
		end
		left = left + cell_size
	end
end

local function DrawCell( index )
	local step = metrics.grid_size / 9

	local left = (window.tex_w / 2) - (metrics.grid_size / 2) + (step / 2)
	local top = (window.tex_h / 2) - (metrics.grid_size / 2) + (step / 2)

	local row, col = IndexToCoords( index )

	local x = left + ((col - 1) * step)
	local y = top + ((row - 1) * step)

	local cell = cells[ index ]

	if cell.color then
		window.pass:setColor( cell.color )
		window.pass:plane( x, y, 0, step, step )
	end

	if cells[ index ].num then
		window.pass:setColor( cell.text_color )
		window.pass:text( cells[ index ].num, x, y, 0, metrics.text_scale )
	end
end

local function DrawAllCells()
	SetAffected()
	SetMatched()
	SetWrong()

	for i, v in ipairs( cells ) do
		DrawCell( i )
	end
end

function GenerateGrid()
	cells = {}
	hidden = {}
	local puzzle
	puzzle, hidden = generate_sudoku_flat( 40 )
	for i, v in ipairs( puzzle ) do
		local editable = false
		if v == 0 then
			v = nil
			editable = true
		end
		local cell = { num = v, editable = editable, color = nil, text_color = e_colors.text }
		table.insert( cells, cell )
	end
end

local function PointInRect( px, py, rx, ry, rw, rh )
	if px >= rx and px <= rx + rw and py >= ry and py <= ry + rh then
		return true
	end

	return false
end

local function TrackMouseState()
	-- Mouse coords: account for aspect ratio
	local mx, my = lovr.system.getMousePosition()
	mouse.x, mouse.y = mx, my
	if window.w > window.tex_w then
		mouse.x = mx - ((window.w - window.tex_w) / 2)
	end
	if window.h > window.tex_h then
		mouse.y = my - ((window.h - window.tex_h) / 2)
	end

	-- Left button state
	if lovr.system.isMouseDown( 1 ) then
		if mouse.button_prev == 0 then
			mouse.button_prev = 1
			mouse.button_curr = 1
			mouse.state = e_mouse_state.clicked
		else
			mouse.button_prev = 1
			mouse.button_curr = 0
			mouse.state = e_mouse_state.held
		end
	else
		mouse.button_prev = 0
		mouse.state = e_mouse_state.released
	end

	local left      = (window.tex_w / 2) - (metrics.grid_size / 2)
	local top       = (window.tex_h / 2) - (metrics.grid_size / 2)
	local cell_size = metrics.grid_size / 9

	local cx        = math.floor( (mouse.x - left) / (cell_size) ) + 1
	local cy        = math.floor( (mouse.y - top) / (cell_size) ) + 1

	if mouse.state == e_mouse_state.clicked then
		if cx >= 1 and cx <= 9 and cy >= 1 and cy <= 9 then
			cur_cell_idx = CoordsToIndex( cy, cx )
		end
	end
end

local function GetKeyboardInput()
	local row, col = IndexToCoords( cur_cell_idx )

	if lovr.system.wasKeyPressed( "right" ) then
		if col < 9 then
			col = col + 1
		end
	elseif lovr.system.wasKeyPressed( "left" ) then
		if col > 1 then
			col = col - 1
		end
	elseif lovr.system.wasKeyPressed( "down" ) then
		if row < 9 then
			row = row + 1
		end
	elseif lovr.system.wasKeyPressed( "up" ) then
		if row > 1 then
			row = row - 1
		end
	elseif lovr.system.wasKeyPressed( "delete" ) or lovr.system.wasKeyPressed( "backspace" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = nil
		end
	elseif lovr.system.wasKeyPressed( "1" ) or lovr.system.wasKeyPressed( "kp1" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 1
		end
	elseif lovr.system.wasKeyPressed( "2" ) or lovr.system.wasKeyPressed( "kp2" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 2
		end
	elseif lovr.system.wasKeyPressed( "3" ) or lovr.system.wasKeyPressed( "kp3" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 3
		end
	elseif lovr.system.wasKeyPressed( "4" ) or lovr.system.wasKeyPressed( "kp4" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 4
		end
	elseif lovr.system.wasKeyPressed( "5" ) or lovr.system.wasKeyPressed( "kp5" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 5
		end
	elseif lovr.system.wasKeyPressed( "6" ) or lovr.system.wasKeyPressed( "kp6" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 6
		end
	elseif lovr.system.wasKeyPressed( "7" ) or lovr.system.wasKeyPressed( "kp7" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 7
		end
	elseif lovr.system.wasKeyPressed( "8" ) or lovr.system.wasKeyPressed( "kp8" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 8
		end
	elseif lovr.system.wasKeyPressed( "9" ) or lovr.system.wasKeyPressed( "kp9" ) then
		if cells[ cur_cell_idx ].editable then
			cells[ cur_cell_idx ].num = 9
		end
	end

	cur_cell_idx = CoordsToIndex( row, col )
end

function Game.Init()
	WindowWasResized()
	window.w, window.h = lovr.system.getWindowDimensions()
	window.tex = lovr.graphics.newTexture( window.w, window.h )
	window.pass = lovr.graphics.newPass( window.tex )

	GenerateGrid()
end

function Game.Update()
	WindowWasResized()
	TrackMouseState()
	GetKeyboardInput()
end

function Game.Render()
	window.pass:setSampler( 'linear' )
	window.pass:reset()
	window.pass:setProjection( 1, mat4():orthographic( window.pass:getDimensions() ) )

	DrawAllCells()
	DrawGrid()

	window.pass:text( "[F2 to Generate new puzzle]", window.tex_w / 2, metrics.msg_top, 0, metrics.text_scale * 0.4 )
end

return Game
