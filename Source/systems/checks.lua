Checks = Checks or {}

local function roll(k)
	if k == 20 then
		return math.random(1,20)
	end
	return math.random(1,6)
end

-- Resolves a skill check: k20 + PLAYER[skill] >= difficulty
function Checks.resolve(skill, difficulty)
	local base = PLAYER[skill] or 0
	local r = roll(20)
	local total = r + base
	return {
		roll = r,
		skill = skill,
		base = base,
		difficulty = difficulty,
		total = total,
		success = (total >= difficulty)
	}
end