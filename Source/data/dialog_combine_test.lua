-- path: Source/data/dialog_combine_test.lua
-- Simple test script for the item-combination system.
-- Flow:
--  - Player can pick up Key Half A and Key Half B.
--  - Player is instructed to press B to open Inventory and combine the halves.
--  - After combining into "key", the gated option becomes available.

DIALOG_COMBINE_TEST = {
	{ id = 1,  type = "line",  speaker = "Narrator",
	  text = "Welcome to the Item Combination Test. You can pick up two halves of a key and combine them.",
	  target = 2 },

	{ id = 2,  type = "choice", prompt = "What do you want to do?",
	  options = {
		{ label = "Get Key Half A", target = 10 },
		{ label = "Get Key Half B", target = 20 },
		{ label = "Open inventory & combine (press B)", target = 3 },
		-- This option is locked until the player holds the full 'key'
		{ label = "Continue (needs Key)", lockedLabel = "Continue (requires Key)", requireItem = "key", target = 100 },
	  }
	},

	{ id = 3, type = "line", speaker = "Narrator",
	  text = "Press B to open the Inventory tab. Select two items and press A twice to try combining them. Press B again to return here.",
	  target = 2 },

	-- Give halves
	{ id = 10, type = "item", speaker = "Narrator",
	  text = "You picked up Key Half A.",
	  item = "key_left",
	  target = 2 },

	{ id = 20, type = "item", speaker = "Narrator",
	  text = "You picked up Key Half B.",
	  item = "key_right",
	  target = 2 },

	-- Success path after player has combined into 'key'
	{ id = 100, type = "line", speaker = "Narrator",
	  text = "Great! You now have a working Key. The combination worked.",
	  target = 101 },

	{ id = 101, type = "choice", prompt = "Combination test complete.",
	  options = {
		{ label = "Loop back to menu prompt", target = 2 },
	  }
	},
}
