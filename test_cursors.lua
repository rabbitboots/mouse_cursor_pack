-- beta


--[[
	LÖVE loader demo for CursorPack.
	Supported LÖVE versions: 11.4

	Repository: TODO

	License for included PNG and SVG cursor graphics: https://creativecommons.org/publicdomain/zero/1.0/

	License for this demo file: MIT License

	Copyright (c) 2022 RBTS

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]


love.keyboard.setKeyRepeat(true)


local cursorLoad = require("cursor_load")


-- cursors -> IDs -> sizes
local cursors = {}

-- In (semi) alphabetical order
local cursors_seq = {}

local show_mouse_xy = false


--[[
	NOTE: This script assumes that the cursors have been exported with hotspot tags embedded into the filenames.
--]]

local function _recursiveEnumerate(folder, _file_list, _folder_list)
	_file_list = _file_list or {}
	_folder_list = _folder_list or {}

	local filesTable = love.filesystem.getDirectoryItems(folder)

	for i, v in ipairs(filesTable) do
		local file = folder .. "/" .. v
		local info = love.filesystem.getInfo(file)

		if not info then
			print("ERROR: failed to get file info for: " .. file)

		else
			if info.type == "file" then
				local ext = string.match(file, ".*%.(.*)$") or ""
				table.insert(_file_list, file)

			elseif info.type == "directory" then
				table.insert(_folder_list, file)
				_recursiveEnumerate(file, _file_list, _folder_list)
			end
		end
	end

	return _file_list, _folder_list
end


local function loadFromPath(path, cursors)
	local file_paths = _recursiveEnumerate(path)

	for i, file_path in ipairs(file_paths) do
		print("Load cursor at:" .. file_path)

		if string.find(file_path, "%.png$") then

			local i_data, id, hx, hy = cursorLoad.loadTaggedFile(file_path)

			-- XXX very hacky
			local px = tonumber(string.match(file_path, "/px_(%d+)/"))

			local cursor = {}

			cursor.id = id
			cursor.px = px
			cursor.hx = hx
			cursor.hy = hy

			cursor.obj = love.mouse.newCursor(i_data, cursor.hx, cursor.hy)
			cursor.img = love.graphics.newImage(i_data)

			if not cursors[cursor.id] then
				cursors[cursor.id] = {id = cursor.id}
			end
			cursors[cursor.id][cursor.px] = cursor
		end
	end
end


-- Load all cursors
loadFromPath("cursors", cursors)


-- Make sorted list for consistent traversal.
do
	local function sort_func(a, b)
		return a.id < b.id;
	end

	-- To reduce flashing imagery, move the plain and inverted versions of cursors to opposite ends of the array.
	local c1, c2 = {}, {}
	for k, v in pairs(cursors) do
		if string.match(k, "invert") then
			table.insert(c1, v)
		else
			table.insert(c2, v)
		end
	end
	table.sort(c1, sort_func)
	table.sort(c2, sort_func)

	for i, v in ipairs(c1) do
		table.insert(cursors_seq, v)
	end
	for i, v in ipairs(c2) do
		table.insert(cursors_seq, v)
	end
end


local cursor_i = 1
local sizes = {8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256}
local size_i = 5

local hardware_mode = true


local function setCursor()
	love.mouse.setCursor(cursors_seq[cursor_i][sizes[size_i]].obj)
end

setCursor()


function love.keypressed(kc, sc)
	local reload_cursor = false

	if sc == "escape" then
		love.event.quit()

	elseif sc == "up" or sc == "w" then
		size_i = math.max(1, size_i - 1)
		setCursor()

	elseif sc == "down" or sc == "s" then
		size_i = math.min(#sizes, size_i + 1)
		setCursor()

	elseif sc == "left" or sc == "a" then
		cursor_i = cursor_i - 1
		if cursor_i < 1 then
			cursor_i = #cursors_seq
		end
		setCursor()

	elseif sc == "right" or sc == "d" then
		cursor_i = cursor_i + 1
		if cursor_i > #cursors_seq then
			cursor_i = 1
		end		
		setCursor()

	elseif sc == "space" then
		show_mouse_xy = not show_mouse_xy

	elseif sc == "tab" then
		hardware_mode = not hardware_mode
		love.mouse.setVisible(hardware_mode)
	end
end


--function love.update(dt)


function love.draw()
	local w, h = love.graphics.getDimensions()
	local mx, my = love.mouse.getPosition()

	local steps = 8
	local step_w = w / steps

	for i = 0, steps - 1 do
		local color = i / steps
		love.graphics.setColor(color, color, color, 1)
		love.graphics.rectangle("fill", i * step_w, 0, step_w, h)
	end

	if show_mouse_xy then
		love.graphics.setColor(1, 0.25, 0.25, 1)
		love.graphics.setLineStyle("rough")
		love.graphics.setLineWidth(1)
		love.graphics.line(0, my, w, my)
		love.graphics.line(mx, 0, mx, h)
	end

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, h - 64, w, 64)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(
		"up/down w/s: change size: " .. sizes[size_i]
		.. "\nleft/right a/d: change cursor: " .. cursors_seq[cursor_i].id
		.. "\nspace: show mouse XY: " .. tostring(show_mouse_xy)
		.. "\ntab: hardware mode: " .. tostring(hardware_mode),
		8, h - 64 + 8)

	love.graphics.print(
		"Escape: quit",
		400, h - 64 + 8)

	if not hardware_mode then
		love.graphics.setColor(1,1,1,1)
		local cursor = cursors_seq[cursor_i][sizes[size_i]]
		love.graphics.draw(cursor.img, mx - cursor.hx, my - cursor.hy)
	end
end


local function testLoadAllCursors()
	for i, cursor in ipairs(cursors_seq) do
		for j, size in ipairs(sizes) do
			print("Test load:", cursor.id, size)
			cursor_i = i
			size_i = j

			setCursor()
		end
	end
end

-- Uncomment to force-load all cursors at application start.
--testLoadAllCursors()

