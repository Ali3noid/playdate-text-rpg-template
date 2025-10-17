std = "lua54+playdate+project"

stds.project = {
   read_globals = {
      -- Podstawowe
      "playdate",
      "import",
      "class",

      -- Systemy
      "Checks",
      "ItemCombiner",

      -- Panele UI
      "LinePanel",
      "ChoicePanel",
      "CheckPanel",
      "InventoryPanel",
      "ImagePanel",
      "EndPanel",

      -- Dane / skrypty
      "ITEMS_01",
      "COMBINATIONS_01",
      "DIALOG_01",
      "DIALOG_COMBINE_TEST",

      -- Klasy scen (na wypadek uzyc globalnie)
      "Dialog",
      "DialogController",
      "DialogState",
      "DialogRenderer",
      "Menu",
      "Inventory",
   }
}

operators = {"+=", "-=", "*=", "/="}
