-- path: Source/systems/inventory.lua
import "CoreLibs/object"
import "data/items_01"   -- provides ITEMS_01

-- Inventory class encapsulates item definitions and acquired items.
-- Each item is defined by an id, name, and description.
-- The inventory stores a list of item ids representing items the
-- player has collected. Methods are provided to add items, check
-- for possession, and retrieve item info.
class('Inventory').extends()

function Inventory:init(definitions)
	-- item definitions table keyed by id
	-- If not provided, fall back to ITEMS_01 loaded from data/items_01.lua
	self.items = definitions or ITEMS_01 or {}
	-- list of acquired item ids
	self.ids = {}
end

-- Add an item by its id to the player's inventory.
-- If the id is unknown, an assertion will be thrown.
function Inventory:add(itemId)
	assert(itemId, "Inventory:add() requires itemId")
	assert(self.items[itemId], "Inventory:add(): unknown item id \"" .. tostring(itemId) .. "\"")
	table.insert(self.ids, itemId)
end

-- Check whether the player currently possesses an item.
-- Returns true if the item id appears in the inventory list.
function Inventory:has(itemId)
	for _, id in ipairs(self.ids) do
		if id == itemId then
			return true
		end
	end
	return false
end

-- Retrieve the definition table for an item id.
-- Returns nil if the id is unknown.
function Inventory:get(itemId)
	return self.items[itemId]
end

-- Return a copy of all acquired item ids.
-- This avoids accidental mutation of the internal list.
function Inventory:getAll()
	local out = {}
	for i, id in ipairs(self.ids) do
		out[i] = id
	end
	return out
end
