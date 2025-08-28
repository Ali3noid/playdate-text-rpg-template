DIALOG_01 = {
	{ type = "line", speaker = "Narrator", text = "Budzisz sie w ciemnej celi." },

	-- 2: Main hub choice
	{ type = "choice", prompt = "Co robisz?", options = {
		{ label = "Rozejrzyj sie", target = 5 },
		{ label = "Krzyknij o pomoc", target = 9 },
		{ label = "Sprobuj otworzyc drzwi", target = 12 },
		{ label = "Pracuj nad soba (trening)", target = 20 }, -- training menu
	}},

	{ type = "line", speaker = "Narrator", text = "(buffer)" },
	{ type = "line", speaker = "Narrator", text = "(buffer)" },

	-- 5
	{ type = "line", speaker = "Ty", text = "Rozgladam sie po celi.", target = 6 },
	{ type = "item", speaker = "Narrator", item = "Klucz", text = "W rogu znajdujesz stary klucz.", target = 7 },
	{ type = "item", speaker = "Narrator", item = "Drut", text = "Za pryczem lezy cienki drut. Moze sie przydac.", target = 8 },
	{ type = "line", speaker = "Narrator", text = "Wroc do drzwi.", target = 2 },

	-- 9
	{ type = "line", speaker = "Ty", text = "Halo! Czy ktos tu jest?", target = 10 },
	{ type = "line", speaker = "Narrator", text = "Twoje wolanie odbija sie echem.", target = 11 },
	{ type = "line", speaker = "Narrator", text = "Nikt ci nie odpowiada. wracasz do drzwi", target = 2 },

	-- 12
	{ type = "choice", prompt = "Jak chcesz otworzyc drzwi?", options = {
		{ label = "Uzyj klucza", target = 13, requireItem = "Klucz" },
		{ label = "Wywaz drzwi", target = 15, requireStat = { name = "Strength", value = 2 } },
		{ label = "Podwaz zamek drutem", target = 17, requireItem = "Drut", requireStat = { name = "Cunning", value = 3 } },
		{ label = "Zrezygnuj", target = 2 },
	}},
	{ type = "line", speaker = "Ty", text = "Przykladasz klucz do zamka.", target = 14 },
	{ type = "line", speaker = "Narrator", text = "Zamek kliknal i drzwi sie otworzyly!", target = 19 },

	-- 15
	{ type = "check", skill = "Strength", difficulty = 10,
		success = {
			{ type = "midCheckLine", speaker = "Narrator", text = "Uderzasz z calej sily i drzwi ustepuja." },
			{ type = "line", speaker = "Narrator", text = "Jestes wolny!", target = 19 },
		},
		fail = {
			{ type = "line", speaker = "Narrator", text = "Probujesz, ale drzwi ani drgna." },
		}
	},
	{ type = "line", speaker = "Narrator", text = "Wracasz do srodka.", target = 2 },

	{ type = "check", skill = "Cunning", difficulty = 12,
		success = {
			{ type = "midCheckLine", speaker = "Narrator", text = "Zamek ustepuje po chwili." },
			{ type = "line", speaker = "Narrator", text = "Drzwi otwarte!", target = 19 },
		},
		fail = {
			{ type = "line", speaker = "Narrator", text = "Nie potrafisz otworzyc zamka drutem." },
		}
	},
	{ type = "line", speaker = "Narrator", text = "Wracasz do srodka.", target = 2 },

	-- 19
	{ type = "line", speaker = "Narrator", text = "Przygoda dobiega konca.", target = nil },

	------------------------------------------------------------------------
	-- 20+: Training submenu
	------------------------------------------------------------------------

	-- 20: training choice
	{ type = "choice", prompt = "Jak chcesz trenowac?", options = {
		{ label = "Pompki i przysiady (+1 Strength)", target = 21 },
		{ label = "Analizuj zamek (+1 Cunning)", target = 24 },
		{ label = "Improwizuj napiecie ramion (+1 Strength)", target = 27 },
		{ label = "Trenuj wyczucie zatrzasku (+1 Cunning)", target = 30 },
		{ label = "Wroc", target = 2 },
	}},

	-- 21
	{ type = "line", speaker = "Narrator", text = "Opierasz dlonie o zimna podloge i liczysz powtorzenia.", target = 22 },
	{ type = "stat", speaker = "Narrator", stat = "Strength", delta = 1, text = "Czujesz, jak miesnie napinaja sie pewniej.", target = 23 },
	{ type = "line", speaker = "Narrator", text = "Odpoczywasz chwile. Moze jeszcze cos potrenowac?", target = 20 },

	-- 24
	{ type = "line", speaker = "Narrator", text = "Przygladasz sie zamkowi, liczysz plytki i szczeliny.", target = 25 },
	{ type = "stat", speaker = "Narrator", stat = "Cunning", delta = 1, text = "Lepiej rozumiesz, co kryje sie w srodku mechanizmu.", target = 26 },
	{ type = "line", speaker = "Narrator", text = "Wyciagasz wnioski i wracasz do planu.", target = 20 },

	-- 27
	{ type = "line", speaker = "Narrator", text = "Uzywasz pryczy jako oporu, napinasz barki w statycznym napieciu.", target = 28 },
	{ type = "stat", speaker = "Narrator", stat = "Strength", delta = 1, text = "Ramiona pracuja, czujesz dodatkowa sile.", target = 29 },
	{ type = "line", speaker = "Narrator", text = "Oddychasz glebiej. Czas na kolejny ruch.", target = 20 },

	-- 30
	{ type = "line", speaker = "Narrator", text = "Z wyczuciem poruszasz drutem, sluchasz klikniec i oporu.", target = 31 },
	{ type = "stat", speaker = "Narrator", stat = "Cunning", delta = 1, text = "Twoj dotyk staje sie precyzyjniejszy.", target = 32 },
	{ type = "line", speaker = "Narrator", text = "Masz wiecej pewnosci przy delikatnych czynnosciach.", target = 20 },
}
