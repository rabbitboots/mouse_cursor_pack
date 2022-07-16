--[[
	Use in LÖVE 11.4 to launch one of multiple source files in the same directory.

	$ love . require.path.to.file

	To run the default file:

	$ love .
--]]

function love.load(arguments)
	require(arguments[1] or "test_cursors")
end
