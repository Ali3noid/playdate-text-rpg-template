-- Simple dialog with one skill check
DIALOG_01 = {
	{ type = "line",   speaker = "Narrator", text = "You wake up to the sound of the crank." },
	{ type = "choice", prompt  = "What do you do?", options = {
		{ label = "Look around", target = 5 },
		{ label = "Call out",    target = 8 },
	}},
	-- buffer entries (3-4)
	{ type = "line", speaker = "Narrator", text = "(buffer)" },
	{ type = "line", speaker = "Narrator", text = "(buffer)" },

	-- id 5 path: line explicitly jumps to the check
	{ type = "line",  speaker = "You", text = "I look around the room.", target = 6 },
	{ type = "check", skill = "Speech", difficulty = 10,
		success = {
			{ type = "line", speaker = "Someone", text = "Hey, are you okay in there?" },
		},
		fail = {
			{ type = "line", speaker = "Narrator", text = "Silence. Maybe next time." },
		}
	},
	{ type = "line", speaker = "Narrator", text = "Press B to return to menu." },

	-- id 8 path: no check
	{ type = "line", speaker = "You",     text = "Hello? Anyone there?" },
	{ type = "line", speaker = "Narrator", text = "Only silence answers you." },
	{ type = "line", speaker = "Narrator", text = "Press B to return to menu." },
}
