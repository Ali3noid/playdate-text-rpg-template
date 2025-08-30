--[[
Checks system implementing Risk Dice and Misfortune mechanics.

This module defines a `Checks` class that can be instantiated to track
Misfortune across multiple tests. Each instance maintains its own
`misfortune` value, which increases whenever a Risk roll fails.
`performTest` rolls a pool of d6 dice (attribute + skill + riskDice),
then applies Misfortune using the following priority:
  1) Reduce only non-success dice (<5) down to 1 first.
  2) Then preserve as many successes as possible:
	 2a) Convert 6 -> 5 (cost 1 each).
	 2b) If Misfortune remains, concentrate it into as few success dice
		 as possible (reduce the highest success fully before touching the next).

Successes are 5–6.

API:
  local checks = Checks()
  local r = checks:performTest(attribute, skill, difficulty, riskDice)
  checks:getMisfortune()
  checks:resetMisfortune()

Result table fields:
  rawRoll, finalRoll, successes, difficulty, passed,
  riskDice, misfortuneBefore, misfortuneAfter
]]

class('Checks').extends()

function Checks:init()
	self.misfortune = 0
end

-- Roll a single d6
local function rollD6()
	return math.random(1, 6)
end

-- Roll N d6
local function rollDice(count)
	local dice = {}
	for i = 1, count do
		dice[i] = rollD6()
	end
	return dice
end

-- Utility: shallow-copy array
local function copyArray(source)
	local out = {}
	for i = 1, #source do out[i] = source[i] end
	return out
end

-- Utility: build list of indices filtered by predicate and sorted by value desc
local function sortedIndicesByValueDesc(values, predicate)
	local idx = {}
	for i = 1, #values do
		if predicate(values[i]) then
			idx[#idx + 1] = i
		end
	end
	table.sort(idx, function(a, b) return values[a] > values[b] end)
	return idx
end

-- Apply Misfortune according to the new rules:
-- 1) Reduce all non-success dice (<5) to 1 before touching successes.
-- 2) Then:
--    2a) Reduce all 6 -> 5 (preserves success count).
--    2b) Concentrate remaining Misfortune on as few success dice as possible,
--        always reducing the highest success fully before touching the next one.
local function applyMisfortune(dice, misfortune)
	if not misfortune or misfortune <= 0 or #dice == 0 then
		return dice
	end

	local adjusted = copyArray(dice)
	local remaining = misfortune

	-- Phase 1: reduce non-success dice (>1 and <5) down to 1
	while remaining > 0 do
		local targets = sortedIndicesByValueDesc(adjusted, function(v) return v > 1 and v < 5 end)
		if #targets == 0 then break end
		for _, i in ipairs(targets) do
			if remaining <= 0 then break end
			local value = adjusted[i]
			-- Reduce as much as possible on this die (pack the cost)
			local canReduce = value - 1
			if canReduce > 0 then
				local take = math.min(canReduce, remaining)
				adjusted[i] = value - take
				remaining = remaining - take
			end
		end
	end

	if remaining <= 0 then
		return adjusted
	end

	-- Phase 2a: convert 6 -> 5 (each costs 1), preserves number of successes
	do
		local sixes = sortedIndicesByValueDesc(adjusted, function(v) return v == 6 end)
		for _, i in ipairs(sixes) do
			if remaining <= 0 then break end
			if adjusted[i] == 6 then
				adjusted[i] = 5
				remaining = remaining - 1
			end
		end
	end

	if remaining <= 0 then
		return adjusted
	end

	-- Phase 2b: sacrifice successes, concentrating on as few dice as possible.
	-- Always pick the highest success (>=5) and reduce it fully before the next.
	while remaining > 0 do
		local successIndices = sortedIndicesByValueDesc(adjusted, function(v) return v >= 5 end)
		if #successIndices == 0 then
			-- No successes left; as a fallback, reduce any remaining dice >1
			local others = sortedIndicesByValueDesc(adjusted, function(v) return v > 1 end)
			if #others == 0 then break end
			for _, i in ipairs(others) do
				if remaining <= 0 then break end
				local value = adjusted[i]
				local canReduce = value - 1
				if canReduce > 0 then
					local take = math.min(canReduce, remaining)
					adjusted[i] = value - take
					remaining = remaining - take
				end
			end
		else
			local i = successIndices[1]
			local value = adjusted[i]
			local canReduce = value - 1
			if canReduce <= 0 then
				-- Should not happen for >=5, but guard anyway
				break
			end
			local take = math.min(canReduce, remaining)
			adjusted[i] = value - take
			remaining = remaining - take
		end
	end

	return adjusted
end

local function countSuccesses(dice)
	local s = 0
	for _, v in ipairs(dice) do
		if v >= 5 then
			s = s + 1
		end
	end
	return s
end

-- Perform a Risk test
function Checks:performTest(attribute, skill, difficulty, riskDice)
	local baseAttr = tonumber(attribute) or 0
	local baseSkill = tonumber(skill) or 0
	local diff = tonumber(difficulty) or 0
	local risk = tonumber(riskDice) or 0
	if risk < 0 then risk = 0 end
	if risk > 2 then risk = 2 end

	local totalDice = math.max(1, baseAttr + baseSkill + risk)
	local raw = rollDice(totalDice)

	local misBefore = self.misfortune
	local adjusted = applyMisfortune(raw, misBefore)

	local successes = countSuccesses(adjusted)
	local passed = (successes >= diff)

	-- If a risky test fails, Misfortune increases by risk
	if risk > 0 and not passed then
		self.misfortune = misBefore + risk
	end

	return {
		rawRoll = raw,
		finalRoll = adjusted,
		successes = successes,
		difficulty = diff,
		passed = passed,
		riskDice = risk,
		misfortuneBefore = misBefore,
		misfortuneAfter = self.misfortune,
	}
end

function Checks:getMisfortune()
	return self.misfortune
end

function Checks:resetMisfortune()
	self.misfortune = 0
end
