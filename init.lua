
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
			return false
		end
	end

	local nodename = itemstack:get_name()
	if not nodename then
		return false
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
		return false
	end
	minetest.sound_play(def.sounds.place, {pos = pos})
	minetest.swap_node(pos, {name = name, param2 = node.param2})
	if not minetest.setting_getbool("creative_mode") then
		itemstack:take_item()
	end
	return itemstack
end

function frame.register(name)
	assert(name, "no content passed")
	local tiles

	local def = minetest.registered_nodes[name]
	if not def then
		-- item?
		def = minetest.registered_items[name]
		assert(def, "not a thing: ".. name)
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
				{name = def.tiles[2] and def.tiles[2].name or def.tiles[1]
					or def.tiles[1] and def.tiles[1].name or def.tiles[1]
					or "doors_blank.png"},
				{name = def.tiles[3] and def.tiles[3].name or def.tiles[3]
					or def.tiles[2] and def.tiles[2].name or def.tiles[2]
					or def.tiles[1] and def.tiles[1].name or def.tiles[1]
					or "doors_blank.png"},
			}
		end
	end
	assert(def, name .. " is not a known node or item")

	local desc = def.description
	local nodename = def.name:gsub(":", "_")

	minetest.register_node("frame:" .. nodename, {
		description = "Frame with " .. desc,
		drawtype = "mesh",
		mesh = "frame.obj",
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		collision_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
		},
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
		},
		sounds = default.node_sound_defaults(),
		groups = {oddly_breakable_by_hand = 1, snappy = 3, not_in_creative_inventory = 1},
		frame_contents = name,
		on_punch = frame_on_punch,
	})
end

-- empty frame
minetest.register_node("frame:empty", {
	description = "Frame",
	drawtype = "mesh",
	mesh = "frame.obj",
	tiles = {
		{name = "frame_frame.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
		{name = "doors_blank.png"},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
	},
	selection_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
	},
	sounds = default.node_sound_defaults(),
	groups = {oddly_breakable_by_hand = 3, cracky = 1},
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

-- default farming nodes
for _, node in pairs({
	"flowers:rose",
	"flowers:tulip",
	"flowers:dandelion_yellow",
	"flowers:geranium",
	"flowers:viola",
	"flowers:dandelion_white",
	"flowers:mushroom_red",
	"flowers:mushroom_brown",
	"flowers:waterlily",
	"farming:cotton_1",
	"farming:cotton_2",
	"farming:cotton_3",
	"farming:cotton_4",
	"farming:cotton_5",
	"farming:cotton_6",
	"farming:cotton_7",
	"farming:cotton_8",
	"farming:wheat_1",
	"farming:wheat_2",
	"farming:wheat_3",
	"farming:wheat_4",
	"farming:wheat_5",
	"farming:wheat_6",
	"farming:wheat_7",
	"farming:wheat_8",
	"farming:wheat",
	"farming:flour",
	"farming:bread",
	"farming:cotton",
	"farming:string",
	"fire:basic_flame",
	"fire:permanent_flame",
	"tnt:gunpowder",
	"tnt:tnt",
	"farming:straw",
	"default:stone",
	"default:cobble",
	"default:stonebrick",
	"default:stone_block",
	"default:mossycobble",
	"default:desert_stone",
	"default:desert_cobble",
	"default:desert_stonebrick",
	"default:desert_stone_block",
	"default:sandstone",
	"default:sandstonebrick",
	"default:sandstone_block",
	"default:obsidian",
	"default:obsidianbrick",
	"default:obsidian_block",
	"default:dirt",
	"default:dirt_with_grass",
	"default:dirt_with_grass_footsteps",
	"default:dirt_with_dry_grass",
	"default:dirt_with_snow",
	"default:sand",
	"default:desert_sand",
	"default:silver_sand",
	"default:gravel",
	"default:clay",
	"default:snow",
	"default:snowblock",
	"default:ice",
	"default:tree",
	"default:wood",
	"default:sapling",
	"default:leaves",
	"default:apple",
	"default:jungletree",
	"default:junglewood",
	"default:jungleleaves",
	"default:junglesapling",
	"default:pine_tree",
	"default:pine_wood",
	"default:pine_needles",
	"default:pine_sapling",
	"default:acacia_tree",
	"default:acacia_wood",
	"default:acacia_leaves",
	"default:acacia_sapling",
	"default:aspen_tree",
	"default:aspen_wood",
	"default:aspen_leaves",
	"default:aspen_sapling",
	"default:stone_with_coal",
	"default:coalblock",
	"default:stone_with_iron",
	"default:steelblock",
	"default:stone_with_copper",
	"default:copperblock",
	"default:bronzeblock",
	"default:stone_with_mese",
	"default:mese",
	"default:stone_with_gold",
	"default:goldblock",
	"default:stone_with_diamond",
	"default:diamondblock",
	"default:cactus",
	"default:papyrus",
	"default:dry_shrub",
	"default:junglegrass",
	"default:grass_1",
	"default:grass_2",
	"default:grass_3",
	"default:grass_4",
	"default:grass_5",
	"default:dry_grass_1",
	"default:dry_grass_2",
	"default:dry_grass_3",
	"default:dry_grass_4",
	"default:dry_grass_5",
	"default:bush_stem",
	"default:bush_leaves",
	"default:acacia_bush_stem",
	"default:acacia_bush_leaves",
	"default:coral_brown",
	"default:coral_orange",
	"default:coral_skeleton",
	"default:water_source",
	"default:water_flowing",
	"default:river_water_source",
	"default:river_water_flowing",
	"default:lava_source",
	"default:lava_flowing",
	"default:torch",
	"default:bookshelf",
	"default:sign_wall_wood",
	"default:sign_wall_steel",
	"default:ladder_wood",
	"default:ladder_steel",
	"default:glass",
	"default:obsidian_glass",
	"default:brick",
	"default:meselamp",
	"default:cloud",
	"default:furnace",
	"default:pick_wood",
	"default:pick_stone",
	"default:pick_steel",
	"default:pick_bronze",
	"default:pick_mese",
	"default:pick_diamond",
	"default:shovel_wood",
	"default:shovel_stone",
	"default:shovel_steel",
	"default:shovel_bronze",
	"default:shovel_mese",
	"default:shovel_diamond",
	"default:axe_wood",
	"default:axe_stone",
	"default:axe_steel",
	"default:axe_bronze",
	"default:axe_mese",
	"default:axe_diamond",
	"default:sword_wood",
	"default:sword_stone",
	"default:sword_steel",
	"default:sword_bronze",
	"default:sword_mese",
	"default:sword_diamond",
	"default:stick",
	"default:paper",
	"default:book",
	"default:book_written",
	"default:coal_lump",
	"default:iron_lump",
	"default:copper_lump",
	"default:mese_crystal",
	"default:gold_lump",
	"default:diamond",
	"default:clay_lump",
	"default:steel_ingot",
	"default:copper_ingot",
	"default:bronze_ingot",
	"default:gold_ingot",
	"default:mese_crystal_fragment",
	"default:clay_brick",
	"default:obsidian_shard",
	"default:flint",
	"nyancat:nyancat",
	"nyancat:nyancat_rainbow",
	"vessels:shelf",
	"vessels:glass_bottle",
	"vessels:drinking_glass",
	"vessels:steel_bottle",
	"vessels:glass_fragments",
	"doors:door_wood",
	"doors:door_steel",
	"doors:door_glass",
	"doors:door_obsidian_glass",
	"doors:trapdoor",
	"doors:trapdoor_steel",
	"beds:bed",
	"beds:fancy_bed",
	"carts:cart",
	"carts:rail",
	"carts:powerrail",
	"carts:brakerail",
	"fire:flint_and_steel",
	"boats:boat",
	"screwdriver:screwdriver",
	"bucket:bucket_empty",
	"bucket:bucket_water",
	"bucket:bucket_river_water",
	"bucket:bucket_lava",
	"wool:white",
	"wool:grey",
	"wool:black",
	"wool:red",
	"wool:yellow",
	"wool:green",
	"wool:cyan",
	"wool:blue",
	"wool:magenta",
	"wool:orange",
	"wool:violet",
	"wool:brown",
	"wool:pink",
	"wool:dark_grey",
	"wool:dark_green",
	"dye:white",
	"dye:grey",
	"dye:black",
	"dye:red",
	"dye:yellow",
	"dye:green",
	"dye:cyan",
	"dye:blue",
	"dye:magenta",
	"dye:orange",
	"dye:violet",
	"dye:brown",
	"dye:pink",
	"dye:dark_grey",
	"dye:dark_green",
}) do
	frame.register(node)
end

-- inception!
frame.register("frame:empty")

