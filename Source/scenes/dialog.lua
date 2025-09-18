-- Thin compatibility shim to keep Main using `Dialog` unchanged.
import "scenes/dialog/dialogController"

class('Dialog').extends(DialogController)

function Dialog:init(config)
    -- Delegate to the controller's init
    DialogController.init(self, config)
end
