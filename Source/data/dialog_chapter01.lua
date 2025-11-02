DIALOG_CHAPTER01 = {

	{ id = 1, type = "line", speaker = "Narrator",
	  text = "Budzi cie chlod. Lezysz na czyms twardym i wilgotnym. Powietrze pachnie stechlizna, jakbys" ..
	   "spala w piwnicy, do ktorej od lat nikt nie zagladal.",
	  target = 2 },

	{ id = 2, type = "image", path = "assets/images/lamp_first_room.png",
	  caption = "Stara lampa naftowa o peknietym szkle.",
	  target = 3 },

	{ id = 3, type = "line", speaker = "Narrator",
	  text = "W polmroku migocze swiatlo lampy naftowej stojacej na drewnianym stole. Jej plomien tanczy" ..
	   "niespokojnie, a cienie skacza po scianach, przypominajac chaotyczne ksztalty.",
	  target = 4 },

	{ id = 4, type = "choice", prompt = "Czy chcesz przyjrzec sie cieniom?",
	  options = {
		{ label = "Tak, przyjrzec sie blizej", target = 5 },
		{ label = "Nie, zignorowac je", target = 6 },
	  }
	},

	{ id = 5, type = "line", speaker = "Narrator",
	  text = "Patrzysz dlugo, az zaczynasz dostrzegac skrzywione, wynaturzone sylwetki. Wysuniete rece," ..
	   "rozciagniete twarze, ciala jak z koszmaru. Po chwili znikaja, jakby nigdy ich nie bylo.",
	  target = 6 },

	{ id = 6, type = "line", speaker = "Narrator",
	  text = "Pomieszczenie jest ciasne. Oprocz stolu widzisz krzeslo i ciezka, zelazna skrzynie. Sciany sa nagie," ..
	  "lecz pokryte brunatnymi zaciekami. Gdy przejedziesz po nich dlonia, masz wrazenie, ze ukladaja sie w twarz" ..
	  "kobiety. Po mrugnieciu plama znika.",
	  target = 7 },

	{ id = 7, type = "image", path = "assets/images/door_first_room.png",
	  caption = "Ciezkie, drewniane drzwi z runicznym znakiem.",
	  target = 8 },

	{ id = 8, type = "line", speaker = "Narrator",
	  text = "Drzwi nie maja klamki od srodka. Zamiast niej ktos wyzlobyl dziwny znak - odwrocony krzyz" ..
	  "spleciony z galezia. Gdy go dotykasz, symbol pulsuje pod twoimi palcami.",
	  target = 9 },

	{ id = 9, type = "check", skill = "Runes", difficulty = 2,
	  success = {
		{ type = "line", speaker = "Narrator",
		  text = "Rozpoznajesz echo pradawnego pisma. Znak ma zwiazek z zakleciami wieziacymi - te drzwi nie sa zwykla bariera.",
		  target = 10 },
	  },
	  fail = {
		{ type = "line", speaker = "Narrator",
		  text = "Znak nic ci nie mowi. Czujesz jedynie chlod, jakby drewno wysysalo z ciebie sily.",
		  target = 10 },
	  }
	},

	{ id = 10, type = "line", speaker = "Narrator",
	  text = "Na stole, obok lampy, lezy zmiety fragment listu. '...procesy w Salem... kobiety znajace ziola... splonely, lecz ich duchy...' - reszte slow pochlonely plamy atramentu.",
	  target = 11 },

	{ id = 11, type = "line", speaker = "Narrator",
	  text = "Twoja uwage przyciaga skrzynia zardzewialym zamkiem. Gdy przykladasz do niej ucho, masz wrazenie, ze cos chrobocze w srodku.",
	  target = 12 },

	{ id = 12, type = "check", skill = "Curses", difficulty = 2,
	  success = {
		{ type = "image", path = "assets/images/chest_first_room.png",
		  caption = "Zardzewiala skrzynia uchylajaca wieko.",
		  target = 13 },
		{ type = "line", speaker = "Narrator",
		  text = "Dotykasz skrzyni i wypowiadasz kilka slow, ktore same przychodza ci do glowy. Zamek skrzypi, a wieko uchyla sie, ukazujac wnetrze... cos porusza sie w srodku.",
		  target = 14 },
	  },
	  fail = {
		{ type = "line", speaker = "Narrator",
		  text = "Szarpiesz skrzynie, ale zamek nie ustepuje. To nie kwestia sily, lecz zaklecia.",
		  target = 14 },
	  }
	},

	{ id = 13, type = "line", speaker = "Narrator",
	  text = "Wstrzasnieta cofasz sie od skrzyni.",
	  target = 14 },

	{ id = 14, type = "choice", prompt = "Co robisz dalej?",
		options = {
		  { label = "Sprobuj wywazyc drzwi sila", target = 15 },
		  { label = "Wsluchaj sie w glos zza sciany", target = 16 },
		  { label = "Otworz wewnetrzne pudelko w skrzyni (zagadka)", target = 21 },
		  { label = "Przyloz amulet do runy", lockedLabel = "Przyloz cos do runy (brak amuletu)", requireItem = "witch_talisman", target = 30 },
		  { label = "Poloz sie z powrotem i zasnij", target = 17 },
		}
	  },

	{ id = 15, type = "line", speaker = "Narrator",
	  text = "Uderzasz barkiem w drzwi, ale te ani drgna. Czujesz tylko piekacy bol. Gdzieś w oddali slyszysz kobiecy glos wypowiadajacy inkantacje.",
	  target = 18 },

	{ id = 16, type = "check", skill = "Curses", difficulty = 1,
	  success = {
		{ type = "line", speaker = "Narrator",
		  text = "Rozpoznajesz fragment sensu: 'wiezy... dusza... zamkniecie'. To zaklecie ochronne.",
		  target = 18 },
	  },
	  fail = {
		{ type = "line", speaker = "Narrator",
		  text = "Nie rozumiesz slow, ale rytm przypomina inkantacje.",
		  target = 18 },
	  }
	},

	{ id = 17, type = "image", path = "assets/images/boy_first_dream.png",
	  caption = "Chlopiec bez twarzy w mroku.",
	  target = 18 },

	{ id = 18, type = "line", speaker = "Narrator",
	  text = "Cokolwiek robilas, dochodzisz do tego samego wniosku: to miejsce nie jest opuszczone. Ktos cie tu trzyma. Ktos, kto zna zaklecia.",
	  target = 19 },

	{ id = 19, type = "line", speaker = "Narrator",
	  text = "W twojej glowie kielkuje zlowlroga mysl: to czarownica.",
	  target = 20 },

	-- ========== Chest logic puzzle ==========
{ id = 21, type = "lock",
	  prompt  = "Mniejsze pudelko ma trzy obrotowe dyski. Napis: 'to co zywi, to co oczyszcza, to co zostaje'.",
	  symbols = { "Lisc", "Plomien", "Popiol" },
	  slots   = 3,
	  initial = { 1, 1, 1 },
	  solution = { 1, 2, 3 }, -- Lisc -> Plomien -> Popiol
	  successText = "Zapadka zwalnia z suchym kliknieciem.",
	  success = {
		{ type = "item", speaker = "Narrator", item = "witch_talisman",
		  text = "W srodku znajduje sie Amulet Czarownicy. Gdy go chwytasz, runa jakby slabnie." },
		{ type = "line", speaker = "Narrator",
		  text = "Amulet lekko grzeje w dloni. Masz wrazenie, ze pragnie dotknac runy na drzwiach.",
		  target = 14 },
	  },
	  failText = "Dyski zgrzytaja i wracaja do pozycji wyjsciowej. To nie ta kolejnosc.",
	  failTarget = 21
	},

	-- ========== Using the reward on the door ==========
	{ id = 30, type = "line", speaker = "Narrator",
	  text = "Przykladasz amulet do wyzlobionego znaku. Pulsowanie ucicha, jakby cos zostalo przepalone do cna.",
	  target = 31 },

	{ id = 31, type = "line", speaker = "Narrator",
	  text = "Z wewnetrznej strony drzwi slychac odsuwajacy sie rygiel. Deski na moment drza, potem opada cisza.",
	  target = 32 },

	{ id = 32, type = "image", path = "assets/images/door_first_room.png",
	  caption = "Runiczny znak blaknie, jakby zostal wyssany.",
	  target = 33 },

	{ id = 33, type = "line", speaker = "Narrator",
	  text = "Drzwi uchylaja sie na szerokosc dloni. Za nimi korytarz ciemniejszy niz to pomieszczenie. Bierzesz wdech.",
	  target = 20 },

	{ id = 20, type = "chapterEnd",
	  text = "Koniec Rozdzialu I." },
}
