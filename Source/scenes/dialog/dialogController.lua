import "CoreLibs/object"
import "CoreLibs/graphics"
import "scenes/dialog/dialogState"
import "scenes/dialog/dialogRenderer"

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

function DialogController:update()
	self.renderer:drawFrame()
end

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
	elseif node.type == "lock" then
		self.state:lockValuePrev()
	elseif (node.type == "line" or node.type == "item" or node.type == "stat" or node.type == "midCheckLine") and (not self.state.typing) then
		if (self.state.lineMaxScroll or 0) > 0 then
			self.state:lineScroll(-1)
		end
	end
end

function DialogController:left()
	local node = self.state.node
	if node ~= nil and node.type == "lock" then
		self.state:lockSlotPrev()
	end
end

function DialogController:right()
	local node = self.state.node
	if node ~= nil and node.type == "lock" then
		self.state:lockSlotNext()
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
	elseif node.type == "lock" then
		self.state:lockValueNext()
	elseif (node.type == "line" or node.type == "item" or node.type == "stat" or node.type == "midCheckLine") and (not self.state.typing) then
		if (self.state.lineMaxScroll or 0) > 0 then
			self.state:lineScroll(1)
		end
	end
end

function DialogController:a()
	if self.state.currentTab == "inventory" then
		self.state:inventoryHandleConfirm()
		return
	end
	local node = self.state.node
	if not node then return end

	local t = node.type
	if t == "line" or t == "midCheckLine" then
		if self.state.typing then
			self.state:typingSkip()
		else
			self.state:routeOrAdvance()
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
			if self.state.applyStatDelta then
				self.state:applyStatDelta()
			end
			self.state:routeOrAdvance()
		end

	elseif t == "choice" then
		self.state:executeChoice()

	elseif t == "check" then
		self.state:checkAdvanceStages()

	elseif t == "image" then
		self.state:routeOrAdvance()

	elseif node.type == "lock" then
		self.state:lockConfirm()
	end
end

function DialogController:b()
	self.state:resetCheckUI()

	if self.state.currentTab == "inventory" then
		if self.state:inventoryCancel() then
			return
		end
		self.state.currentTab = "dialog"
		return
	end

	if self.state.currentTab == "dialog" then
		self.state.currentTab = "inventory"
		if not self.state.inventorySelectedIndex or self.state.inventorySelectedIndex < 1 then
			self.state.inventorySelectedIndex = 1
		end
		return
	end
end
