std = "lua54+playdate+project"

stds.project = {
   globals = {
   "Checks",
   "ItemCombiner",
   
   "LinePanel",
   "ChoicePanel",
   "CheckPanel",
   "InventoryPanel",
   "ImagePanel",
   "EndPanel",
   "LockPanel",

   "Dialog",
   "DialogController",
   "DialogState",
   "DialogRenderer",
   "Menu",
   "Inventory"
   },
   
   read_globals = {
      "playdate",
      "import",
      "class",

      "ITEMS_01",
      "COMBINATIONS_01",
      "DIALOG_01",
      "DIALOG_COMBINE_TEST",
      "DIALOG_CHAPTER01"
   }
}

operators = {"+=", "-=", "*=", "/="}
