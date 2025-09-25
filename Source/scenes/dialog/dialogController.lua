import "CoreLibs/object"
import "CoreLibs/graphics"
import "scenes/dialog/dialogState"
import "scenes/dialog/dialogRenderer"

-- Orchestrates the scene: wires state + renderer, delegates input.
class('DialogController').extends()

function DialogController:init(configOrSwitch, script, stats, inventory)
	local cfg
	if type(configOrSwitch) == "table" then
		cfg = configOrSwitch
	else
		cfg = { switch = configOrSwitch, script = script, stats = stats, inventory = inventory }
	end

	self.switch   = assert(cfg.switch, "DialogController: missing switch()")
	self.state    = DialogState(cfg)
	self.renderer = DialogRenderer(self.state)
end

function DialogController:enter() end
function DialogController:leave() end

function DialogController:update()
	self.renderer:drawFrame()
end

-- Input maps to state ops; renderer re-reads state each frame.

function DialogController:up()
	if self.state.currentTab == "inventory" then
		self.state:inventorySelectPrev()
		return
	end
	local node = self.state.node
	if not node then return end
	if node.type == "choice" and self.state.mode == nil then
		self.state:choicePrev()
	elseif node.type == "check" and self.state.mode == "diceSelect" then
		self.state:decreaseRisk()
	end
end

function DialogController:down()
	if self.state.currentTab == "inventory" then
		self.state:inventorySelectNext()
		return
	end
	local node = self.state.node
	if not node then return end
	if node.type == "choice" and self.state.mode == nil then
		self.state:choiceNext()
	elseif node.type == "check" and self.state.mode == "diceSelect" then
		self.state:increaseRisk()
	end
end

function DialogController:a()
	if self.state.currentTab == "inventory" then
		-- reserved for future use (use/equip/examine)
		return
	end
	local node = self.state.node
	if not node then return end

	local t = node.type
	if t == "line" then
		if self.state.typing then
			self.state:typingSkip()
		else
			self.state:routeOrAdvance()
		end

	elseif t == "midCheckLine" then
		if self.state.typing then
			self.state:typingSkip()
		else
			self.state:advance()
		end

	elseif t == "item" then
		if self.state.typing then
			self.state:typingSkip()
		else
			self.state:giveItemIfAny()
			self.state:routeOrAdvance()
		end

	elseif t == "stat" then
		if self.state.typing then
			self.state:typingSkip()
		else
			self.state:applyStatDelta()
			self.state:routeOrAdvance()
		end

	elseif t == "choice" then
		self.state:executeChoice()

	elseif t == "check" then
		self.state:checkAdvanceStages()
	end
end

function DialogController:b()
	-- Clear transient dice UI
	self.state:resetCheckUI()

	-- Toggle tabs
	if self.state.currentTab == "dialog" then
		self.state.currentTab = "inventory"
		if not self.state.inventorySelectedIndex or self.state.inventorySelectedIndex < 1 then
			self.state.inventorySelectedIndex = 1
		end
	else
		self.state.currentTab = "dialog"
	end
end
