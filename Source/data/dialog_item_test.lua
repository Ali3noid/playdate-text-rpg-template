-- Simple script to test item pickup nodes.
-- Use B to open the inventory and verify that the item appears.
DIALOG_ITEM_TEST = {
	{ id = 1, type = "line", speaker = "Narrator",
		text = "Item Test. This scene will award you a test item. If the text is longer than the box, use Up/Down to scroll. Press A at the bottom to proceed." },
	{ id = 2, type = "item", speaker = "Narrator",
		text = "You found a strange amulet. It will be added to your inventory when you press A at the bottom.",
		item = "witch_talisman" },
	{ id = 3, type = "line", speaker = "Narrator",
		text = "Press B to open Inventory. You should see 'debugAmulet'. Press A to continue." },
	{ id = 4, type = "choice", prompt = "What next?",
		options = {
			{ label = "Back to Menu", target = 99 },
			{ label = "Give me the item again", target = 2 },
		}
	},
	{ id = 99, type = "chapterEnd", text = "End of Item Test." },
}
