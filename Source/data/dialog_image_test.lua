DIALOG_IMAGE_TEST = {
	{ id = 1, type = "line", speaker = "Narrator",
	  text = "Witaj w Image Test. Wybierz scene, nacisnij A, aby zobaczyc obraz.",
	  target = 2 },

	{ id = 2, type = "choice", prompt = "Ktory obraz chcesz wyswietlic?", options = {
		-- { label = "Drzwi z runem",            target = 10 },
		-- { label = "Skrzynia",                 target = 20 },
		-- { label = "Chlopiec w mroku",         target = 30 },
		{ label = "Peknieta lampa",           target = 40 },
		{ label = "Brak pliku (fallback)",    target = 50 },
		{ label = "End (powrot A)",           target = 100 },
	}},

	-- Each image node is fullscreen; A continues back to hub (target=2)
	{ id = 10, type = "image",
	  path = "images/door_400x240.png",
	  target = 2 },

	{ id = 20, type = "image",
	  path = "images/chest_400x240.png",
	  target = 2 },

	{ id = 30, type = "image",
	  path = "images/boy_shadow_400x240.png",
	  target = 2 },

	{ id = 40, type = "image",
	  path = "assets/images/lamp_first_room.png",
	  target = 2 },

	-- Intentionally missing to test fallback text
	{ id = 50, type = "image",
	  path = "images/does_not_exist.png",
	  caption = "Ten plik nie istnieje (spodziewany fallback).",
	  target = 2 },

	{ id = 100, type = "chapterEnd",
	  text = "To koniec testu obrazkow. Wcisnij A by wrocic do menu." },
}
