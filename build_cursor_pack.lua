--[[
	WARNING: This script is incomplete and hasn't been thoroughly tested. See 'TODO' notes below.

	Exports SVG cursors, applies cut-out alpha transparency to raster images, and sorts all
	images by size class.

	Inkscape is required for exporting SVG images. Despite the love.filesystem codepath stuff,
	NativeFS is currently required.

	To run:

	LÖVE 11.4:
	love . build_cursor_pack

	LÖVE 12.0: (untested)
	love build_cursor_pack.lua
--]]

--[[
	TODO: Could this be rewritten as a Python script? Even though it was designed to make cursors for LÖVE,
	there technically isn't anything here that actually requires it.

	TODO: Do something about the Inkscape command hanging the main thread.

	TODO: This code, particularly the directory-handling logic, was written hastily and is pretty fragile.

	TODO: Test love filesystem code path

	TODO: Test on Windows
		-> Raster export works, but I haven't tested with Inkscape installed yet.
--]]


local time_start = love.timer.getTime()

-- Helps parse filenames
local cursorLoad = require("cursor_load")

-- Libraries
local nativefs = require("lib.nativefs")

--[[
	Size classes are hard-coded for now.
--]]

local size_raster = {8, 12, 16, 24, 32,}
local size_vector = {48, 64, 96, 128, 192, 256,}
local size_all = {}
for i, size in ipairs(size_raster) do
	table.insert(size_all, size)
end
for i, size in ipairs(size_vector) do
	table.insert(size_all, size)
end

-- * Filesystem wrappers * --

local fs_backend = "nfs"
local build_hs_mode = "encode_in_file" -- "encode_in_file", "write_hotspot_file"
--build_hs_mode = "write_hotspot_file"

local function fs_getBaseDir()
	if fs_backend == "lfs" then
		return ""
	else
		return nativefs.getWorkingDirectory() .. "/"
	end
end


local function fs_getInfo(file)
	if fs_backend == "lfs" then
		return love.filesystem.getInfo(file)
	elseif fs_backend == "nfs" then
		return nativefs.getInfo(file)
	else
		error("invalid filesystem backend: " .. fs_backend)
	end
end


local function fs_getDirectoryItems(folder)
	if fs_backend == "lfs" then
		return love.filesystem.getDirectoryItems(folder)
	elseif fs_backend == "nfs" then
		return nativefs.getDirectoryItems(folder)
	else
		error("invalid filesystem backend: " .. fs_backend)
	end
end


local function fs_newFileData(path)
	local f_data, err
	if fs_backend == "lfs" then
		f_data, err = love.filesystem.newFileData(path)
	elseif fs_backend == "nfs" then
		f_data, err = nativefs.newFileData(path)
	else
		error("invalid filesystem backend: " .. fs_backend)
	end

	if not f_data then
		error(err)
	else
		return f_data
	end
end


local function fs_remove(path)
	local ok, err

	if fs_backend == "lfs" then
		ok, err = love.filesystem.remove(path)
	elseif fs_backend == "nfs" then
		ok, err = nativefs.remove(path)
	else
		error("invalid filesystem backend: " .. fs_backend)
	end

	if not ok then
		error("failed to delete '" .. tostring(path) .. "': " .. tostring(err))
	end
end


local function fs_createDir(path)
	local ok, err

	if fs_backend == "lfs" then
		ok, err = love.filesystem.createDirectory(path)
	elseif fs_backend == "nfs" then
		ok, err = nativefs.createDirectory(path)
	end

	if not ok then
		error(err or "failed to create directory: " .. path) -- lf.createDirectory doesn't return an error string on failure
	end
end


local function _recursiveEnumerate(folder, _file_list, _folder_list)
	_file_list = _file_list or {}
	_folder_list = _folder_list or {}

	local filesTable = fs_getDirectoryItems(folder)

	for i, v in ipairs(filesTable) do
		local file = folder .. "/" .. v
		local info = fs_getInfo(file)

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


local function _recursiveDelete(folder)
	local files, folders = _recursiveEnumerate(folder)
	for i, file in ipairs(files) do
		fs_remove(file)
	end
	
	for i = #folders, 1, -1 do
		fs_remove(folders[i])
	end
end


-- * / Filesystem wrappers * --


local base_dir = fs_getBaseDir()
local dir_cursors = base_dir .. "cursors"

-- Delete contents of 'cursors'. If you are making changes to the script, back up
-- the last known good output before running.
_recursiveDelete(base_dir .. "cursors")


-- Get directory details
local raster_files, raster_folders = _recursiveEnumerate(base_dir .. "wip-raster")
local vector_files, vector_folders = _recursiveEnumerate(base_dir .. "wip-vector")

-- Add folders to 'cursors' for every folder found in the above calls.
local function makeFolders(folders, base_len)
	for i, dir in ipairs(folders) do
		local trimmed_dir = string.sub(dir, base_len)

		for j, size in ipairs(size_all) do
			local dest_dir = dir_cursors .. "/px_" .. tostring(size) .. "/" .. trimmed_dir
			local info = fs_getInfo(dest_dir)
			if not info or (info and info.type ~= "directory") then
				fs_createDir(dest_dir)
			end
		end
	end
end
makeFolders(raster_folders, #base_dir + #"wip-raster/" + 1)
makeFolders(vector_folders, #base_dir + #"wip-vector/" + 1)


-- Load raster images, apply cut-out alpha transparency, and save to destination
for i, i_file in ipairs(raster_files) do
	local f_data = fs_newFileData(i_file)
	local i_data = love.image.newImageData(f_data)

	for y = 0, i_data:getHeight() - 1 do
		for x = 0, i_data:getWidth() - 1 do
			local pr, pg, pb = i_data:getPixel(x, y)
			if pr == 1 and pg == 0 and pb == 1 then
				i_data:setPixel(x, y, 0, 0, 0, 0)
			end
		end
	end

	local id, hx, hy = cursorLoad.getTagsFromFilePath(i_file)

	-- XXX pretty hacky
	local px = string.match(i_file, "%-px_(%d+)_")

	local path_out = string.sub(i_file, #base_dir + #"wip-raster/" + 1)
	path_out = string.match(path_out, "(.*)/[^/]*$")
	
	local file_out
	local file_hs_out
	if build_hs_mode == "encode_in_file" then
		file_out = id .. "-hx_" .. hx .. "_hy_" .. hy .. ".png"
	else
		file_out = id .. ".png"
		file_hs_out = id .. ".hotspot"
	end

	local final_out = dir_cursors .. "/px_" .. tostring(px) .. "/" .. path_out .. "/" .. file_out

	print("RASTER: write " .. final_out)

	local out_data = i_data:encode("png")
	nativefs.write(final_out, out_data)

	if build_hs_mode == "write_hotspot_file" then
		local hs_str = "hx " .. hx .. "\nhy " .. hy
		nativefs.write(dir_cursors .. "/px_" .. tostring(px) .. "/" .. path_out .. "/" .. file_hs_out, hs_str)
	end
end


-- Export SVGs with Inkscape.
for i, i_file in ipairs(vector_files) do

	-- Separate ID and tags from filename.
	-- We will scale and floor the hotspot for every exported size.
	local id, hx, hy = cursorLoad.getTagsFromFilePath(i_file)

	-- XXX pretty hacky. This is already expected to be 64.
	local px = string.match(i_file, "%-px_(%d+)_")

	hx = hx / px
	hy = hy / px

	for s, size in ipairs(size_vector) do
		local path_out = string.sub(i_file, #base_dir + #"wip-vector/" + 1)
		path_out = string.match(path_out, "(.*)/[^/]*$")

		local name_out
		local file_hs_out
		if build_hs_mode == "encode_in_file" then
			name_out = id .. "-hx_" .. math.floor(hx * size) .. "_hy_" .. math.floor(hy * size) .. ".png"
		else
			name_out = id .. ".png"
			file_hs_out = id .. ".hotspot"
		end

		local final_out = dir_cursors .. "/px_" .. size .. "/" .. path_out .. "/" .. name_out
		print("VECTOR: write " .. final_out)
		local command = "inkscape -w " .. size .. " -h " .. size .. " " .. i_file .. " -o " .. final_out

		local result = os.execute(command)

		if build_hs_mode == "write_hotspot_file" then
			local hs_str = "hx " .. math.floor(hx * size) .. "\nhy " .. math.floor(hy * size)
			nativefs.write(dir_cursors .. "/px_" .. size .. "/" .. path_out .. "/" .. file_hs_out, hs_str)
		end

		if not result then
			error("inkscape command failed: " .. command)
		end
		love.timer.sleep(0.01)
	end
end

print("\n\nAll done! Time in seconds: " .. love.timer.getTime() - time_start .. "\n\n")

love.event.quit()

