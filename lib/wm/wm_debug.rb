module WM
  module DebugWM
    def swap_alt_ctrl()
      km = WM::KeyMap
        
      alt,ctrl            = km[:Alt],km[:Ctrl]
      km[:Alt]            = ctrl
      km[:Ctrl]           = alt 
        
      altshift,ctrlshift  = km[:AltShift],km[:CtrlShift]
      km[:CtrlShift]      = altshift
      km[:AltShift]       = ctrlshift
    end
  end
end
