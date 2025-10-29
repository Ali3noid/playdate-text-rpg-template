-- Simple script to test stat nodes. Each pass through will add +2 Strength.
DIALOG_STAT_TEST = {
	{ id = 1, type = "line", speaker = "Narrator",
		text = "Stat Test. This scene will increase Strength by +2 when you confirm the stat node. Use Up/Down to scroll if needed. Press A at the bottom to confirm." },
	{ id = 2, type = "stat", speaker = "Narrator",
		text = "You feel tougher already. Confirm to gain +2 Strength.",
		stat = "Strength", delta = 2 },
	{ id = 3, type = "line", speaker = "Narrator",
		text = "Strength increased by +2. Run this multiple times to stack. Press A to continue." },
	{ id = 4, type = "choice", prompt = "What next?",
		options = {
			{ label = "Back to Menu", target = 99 },
			{ label = "this require 2 str", target = 2, requireStat = { name = "Strength", value = 2 } },
		}
	},
	{ id = 99, type = "chapterEnd", text = "End of Stat Test." },
}
