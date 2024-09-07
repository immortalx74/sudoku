local hidden = {}
-- Function to check if a number can be placed at a position
local function is_valid( grid, row, col, num )
	for i = 1, 9 do
		if grid[ row ][ i ] == num or grid[ i ][ col ] == num then
			return false
		end
	end

	-- Check 3x3 box
	local start_row = math.floor( (row - 1) / 3 ) * 3 + 1
	local start_col = math.floor( (col - 1) / 3 ) * 3 + 1
	for i = start_row, start_row + 2 do
		for j = start_col, start_col + 2 do
			if grid[ i ][ j ] == num then
				return false
			end
		end
	end

	return true
end

-- Function to solve the Sudoku (backtracking algorithm)
local function solve_sudoku( grid )
	for row = 1, 9 do
		for col = 1, 9 do
			if grid[ row ][ col ] == 0 then
				for num = 1, 9 do
					if is_valid( grid, row, col, num ) then
						grid[ row ][ col ] = num
						if solve_sudoku( grid ) then
							return true
						else
							grid[ row ][ col ] = 0
						end
					end
				end
				return false
			end
		end
	end
	return true
end

-- Function to generate a complete Sudoku grid
local function generate_complete_grid()
	local grid = {}
	for i = 1, 9 do
		grid[ i ] = {}
		for j = 1, 9 do
			grid[ i ][ j ] = 0
		end
	end

	-- Randomly fill diagonal 3x3 grids
	local function fill_diagonal_boxes()
		for i = 1, 9, 3 do
			local nums = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
			for row = i, i + 2 do
				for col = i, i + 2 do
					local index = math.random( #nums )
					grid[ row ][ col ] = table.remove( nums, index )
				end
			end
		end
	end

	fill_diagonal_boxes()

	-- Solve the partially filled grid
	solve_sudoku( grid )

	return grid
end

-- Function to remove numbers from a solved grid to make a puzzle
local function remove_numbers( grid, difficulty )
	local attempts = difficulty -- Difficulty based on number of removed elements
	while attempts > 0 do
		local row = math.random( 1, 9 )
		local col = math.random( 1, 9 )
		while grid[ row ][ col ] == 0 do
			row = math.random( 1, 9 )
			col = math.random( 1, 9 )
		end
		table.insert( hidden, { row = row, col = col, num = grid[ row ][ col ] } )
		grid[ row ][ col ] = 0
		attempts = attempts - 1
	end
end

-- Function to flatten the 2D grid into a 1D array
local function flatten_grid( grid )
	local flat_grid = {}
	for row = 1, 9 do
		for col = 1, 9 do
			table.insert( flat_grid, grid[ row ][ col ] )
		end
	end
	return flat_grid
end

-- Main function to generate and return a Sudoku puzzle as a flat array
function generate_sudoku_flat( difficulty )
	local grid = generate_complete_grid()
	remove_numbers( grid, difficulty )
	local flat_grid = flatten_grid( grid )
	return flat_grid, hidden
end

math.randomseed( os.time() ) -- Initialize random seed
