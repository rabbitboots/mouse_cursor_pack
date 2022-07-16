--[[
	CursorLoad -- part of the CursorMgr package
	License: Source code is MIT, demo cursor art is CC0
--]]


local cursorLoad = {}


-- * Internal *


local function getIntProperty(str, id, strict)

	local retval

	local i, j = string.find(str, id)
	if i then
		retval = tonumber(string.match(str, "%d+", j + 1))
	end

	if not retval and strict then
		error("missing cursor tag: " .. id)
	end

	return retval
end


-- * / Internal *


--- Utility function to parse the cursor ID and hotspot tags within filenames.
-- @param file_path Filename, optionally including the path (which will be trimmed) (forward slashes as separators only).
-- @return The ID, X hotspot and Y hotspot parsed from the file path.
function cursorLoad.getTagsFromFilePath(file_path)

	-- Remove leading path, if applicable.
	local id = string.match(file_path, "/*([^/]*)$")

	-- Separate ID and tagged regions
	local tag_str = string.match(id, "%-(.*)%..*$")

	id = string.match(id, "([^%-]*)%-")

	if not tag_str then
		error("couldn't extract tag substring from file path.")
	end

	local hx = getIntProperty(tag_str, "hx_", true)
	local hy = getIntProperty(tag_str, "hy_", true)

	return id, hx, hy
end


--- Load an image with tagged cursor metadata.
-- @param file_path Path and name of the image file.
-- @return ImageData created from the file path, and the ID, hotspot X and hotspot Y positions parsed from the file.
function cursorLoad.loadTaggedFile(file_path)

	local id, hx, hy = cursorLoad.getTagsFromFilePath(file_path)
	local i_data = love.image.newImageData(file_path)

	return i_data, id, hx, hy
end


--- Load an image with a paired .hotspot file containing cursor metadata.
-- @param file_path Path and name of the image file.
-- @param hotspot_path If the .hotspot file is not located in the same path as 'file_path', specify it here. Otherwise, leave this blank.
-- @return ImageData created from the file path, and the ID, hotspot X and hotspot Y positions parsed from the file.
function cursorLoad.loadFilePair(file_path, hotspot_path)

	local i_data = love.image.newImageData(file_path)

	hotspot_path = hotspot_path or (string.match(file_path, "(.*)%..*$") .. ".hotspot")

	-- Remove leading path, if applicable.
	local id = string.match(file_path, "/*([^/]*)$")
	id = string.match(id, "([^%.]*)%.")

	local hs_contents, size_or_err = love.filesystem.read("string", hotspot_path)

	if not hs_contents then
		error("failed to load .hotspot file: " .. tostring(size_or_err))
	end

	local hx = getIntProperty(hs_contents, "hx ", true)
	local hy = getIntProperty(hs_contents, "hy ", true)

	return i_data, id, hx, hy
end


return cursorLoad
