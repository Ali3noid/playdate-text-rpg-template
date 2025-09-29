import "CoreLibs/object"
import "data/combinations_01"

class('ItemCombiner').extends()

function ItemCombiner:init(recipes)
	self.recipes = recipes or COMBINATIONS_01 or {}
end

local function matchUnordered(a, b, x, y)
	-- true if sets {a,b} and {x,y} are equal ignoring order
	return (a == x and b == y) or (a == y and b == x)
end

-- Removes one occurrence of id from a sequential table
local function removeOne(tbl, id)
	for i = 1, #tbl do
		if tbl[i] == id then
			table.remove(tbl, i)
			return true
		end
	end
	return false
end

-- Attempt to combine two item ids in the given inventory (list or Inventory class).
-- Returns: resultId on success, or nil on failure.
function ItemCombiner:attemptCombine(inventory, firstId, secondId)
	if not (inventory and firstId and secondId) then return nil end
	if firstId == secondId then return nil end

	for _, recipe in ipairs(self.recipes) do
		local ins = recipe.inputs or {}
		if #ins == 2 and matchUnordered(ins[1], ins[2], firstId, secondId) then
			-- Remove inputs
			if type(inventory) == "table" and inventory.remove and type(inventory.remove) == "function" then
				inventory:remove(firstId); inventory:remove(secondId)
				inventory:add(recipe.result)
			else
				-- raw list fallback
				removeOne(inventory, firstId); removeOne(inventory, secondId)
				table.insert(inventory, recipe.result)
			end
			return recipe.result
		end
	end
	return nil
end
