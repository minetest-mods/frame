
--[[

  Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

  "frame" is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of
  the license, or (at your option) any later version.

--]]

frame = {}

-- handle node removal from frame
local function frame_on_punch(pos, node, puncher, pointed_thing)
	if puncher and not minetest.check_player_privs(puncher, "protection_bypass") then
		local name = puncher:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return false
		end
	end

	local def = minetest.registered_nodes[node.name]
	local item = ItemStack(def.frame_contents)

	-- preserve itemstack metadata and wear
	local meta = minetest.get_meta(pos)
	local wear = meta:get_int("wear")
	if wear then
		item:set_wear(wear)
	end
	local metadata = meta:get_string("metadata")
	if metadata ~= "" then
		item:set_metadata(metadata)
	end

	--minetest.handle_node_drops(pos, {item}, puncher)
	local inv = puncher:get_inventory()
	if inv:room_for_item("main", item) then
		inv:add_item("main", item)
		minetest.sound_play(def.sounds.dug, {pos = pos})
		minetest.swap_node(pos, {name = "frame:empty", param2 = node.param2})
	end
end

-- handle node insertion into frame
local function frame_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
		local name = clicker:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return itemstack
		end
	end

	local nodename = itemstack:get_name()
	if not nodename then
		return itemstack
	end

	local wear = itemstack:get_wear()
	if wear then
		local meta = minetest.get_meta(pos)
		meta:set_int("wear", wear)
	end
	local metadata = itemstack:get_metadata()
	if metadata ~= "" then
		local meta = minetest.get_meta(pos)
		meta:set_string("metadata", metadata)
	end

	local name = "frame:" .. nodename:gsub(":", "_")
	local def = minetest.registered_nodes[name]
	if not def then
		def = minetest.registered_items[name]
		if not def then
			return itemstack
		end
	end
	minetest.sound_play(def.sounds.place, {pos = pos})
	minetest.swap_node(pos, {name = name, param2 = node.param2})
	if not minetest.settings:get_bool("creative_mode") then
		itemstack:take_item()
	end
	return itemstack
end

function frame.register(name)
	assert(name, "no content passed")
	assert(string.sub(name, 1, 1) ~= ":", "name must not start with ':'")

	local tiles

	local def = minetest.registered_nodes[name]
	if not def then
		-- item?
		def = minetest.registered_items[name]
		if not def then
			-- nonexistant item.
			minetest.log("warning", "Frame registered for \"" .. name .. "\" but it isn't registered")
			return
		end
		assert(def.inventory_image, "no inventory image for " .. name)

		tiles = {
			{name = "frame_frame.png"},
			{name = def.inventory_image},
			{name = "doors_blank.png"},
			{name = "doors_blank.png"},
			{name = "doors_blank.png"},
		}
	else
		-- node
		if def.inventory_image ~= "" then
			-- custom inventory override image first.
			tiles = {
				{name = "frame_frame.png"},
				{name = def.inventory_image or "doors_blank.png"},
				{name = "doors_blank.png"},
				{name = "doors_blank.png"},
				{name = "doors_blank.png"},
			}
		elseif def.drawtype ~= "normal" then
			-- use tiles[1] only, but on frame
			tiles = {
				{name = "frame_frame.png"},
				{name = def.tiles[1] and def.tiles[1].name or def.tiles[1] or "doors_blank.png"},
				{name = "doors_blank.png"},
				{name = "doors_blank.png"},
				{name = "doors_blank.png"},
			}
		else -- type(def.tiles[1]) == "table" then
			-- multiple tiles
			tiles = {
				{name = "frame_frame.png"},
				{name = "doors_blank.png"},
				{name = def.tiles[1] and def.tiles[1].name or def.tiles[1]
					or "doors_blank.png"},
				{name = def.tiles[2] and def.tiles[2].name or def.tiles[2]
					or def.tiles[1] and def.tiles[1].name or def.tiles[1]
					or "doors_blank.png"},
				{name = def.tiles[6] and def.tiles[6].name or def.tiles[6]
				        or def.tiles[3] and def.tiles[3].name or def.tiles[3]
					or def.tiles[2] and def.tiles[2].name or def.tiles[2]
					or def.tiles[1] and def.tiles[1].name or def.tiles[1]
					or "doors_blank.png"},
			}
		end
	end
	assert(def, name .. " is not a known node or item")

	minetest.register_node(":frame:" .. name:gsub(":", "_"), {
		description = "Item Frame with " .. def.description,
		drawtype = "mesh",
		mesh = "frame.obj",
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "wallmounted",
			wall_side = {-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
		},
		sounds = default.node_sound_defaults(),
		groups = {attached_node = 1, oddly_breakable_by_hand = 1, snappy = 3, not_in_creative_inventory = 1},
		frame_contents = name,
		drop = "frame:empty", -- FIXME item should be in there but this would allow free repair
		on_punch = frame_on_punch,
	})
end

-- empty frame
minetest.register_node("frame:empty", {
	description = "Item Frame",
	drawtype = "mesh",
	mesh = "frame.obj",
	inventory_image = "frame_frame.png",
	wield_image = "frame_frame.png",
	tiles = {
		{name = "frame_frame.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
	},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "wallmounted",
		wall_side = {-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
	},
	sounds = default.node_sound_defaults(),
	groups = {attached_node = 1, oddly_breakable_by_hand = 3, cracky = 1},
	on_rightclick = frame_on_rightclick,
})

-- craft
minetest.register_craft({
	output = "frame:empty",
	recipe = {
		{"default:stick", "default:stick", "default:stick"},
		{"default:stick", "default:paper", "default:stick"},
		{"default:stick", "default:stick", "default:stick"},
	}
})

local items_to_frame = {}

for _, node in pairs(minetest.registered_items) do
    if (minetest.get_item_group(node.name, "not_in_creative_inventory") == 0 and
    node.drawtype ~= "airlike" and
    node.drawtype ~= "nodebox" and
    node.drawtype ~= "mesh") or
    ((node.drawtype == "nodebox" or
    node.drawtype == "mesh") and
    node.inventory_image ~= "") then
        table.insert(items_to_frame, node.name)
    end
end

for _, node in pairs(items_to_frame) do
	frame.register(node)
end
