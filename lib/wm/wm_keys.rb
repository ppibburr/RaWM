
module WM
  KeyMap = {}
  
  def KeyMap.find_by_symbol sym
    pair = find do |k,v|
      sym == k
    end
    
    return unless pair
    return pair[1]
  end
  
  KeyMap[:F1]        = 67
  KeyMap[:F2]        = 68
  KeyMap[:F3]        = 69
  KeyMap[:F4]        = 70
  KeyMap[:F5]        = 71
  KeyMap[:F6]        = 72
  KeyMap[:F7]        = 73
  KeyMap[:F8]        = 74
  KeyMap[:F9]        = 75
  KeyMap[:F10]       = 76
  KeyMap[:q]         = 24
  KeyMap[:w]         = 25
  KeyMap[:e]         = 26
  KeyMap[:r]         = 27
  KeyMap[:t]         = 28
  KeyMap[:y]         = 29
  KeyMap[:u]         = 30
  KeyMap[:i]         = 31
  KeyMap[:o]         = 32
  KeyMap[:p]         = 33
  KeyMap[:a]         = 38
  KeyMap[:s]         = 39
  KeyMap[:d]         = 40
  KeyMap[:f]         = 41
  KeyMap[:g]         = 42
  KeyMap[:h]         = 43
  KeyMap[:j]         = 44
  KeyMap[:k]         = 45
  KeyMap[:l]         = 46
  KeyMap[:z]         = 52
  KeyMap[:x]         = 53
  KeyMap[:c]         = 54
  KeyMap[:v]         = 55
  KeyMap[:b]         = 56
  KeyMap[:n]         = 57
  KeyMap[:m]         = 58
  
  KeyMap[:Space]     = 65
  KeyMap[:Enter]     = 36
  
  KeyMap[:Left]      = 113
  KeyMap[:Right]     = 114
  KeyMap[:Up]        = 111
  KeyMap[:Down]      = 116

  KeyMap[:AltCtrl]   = XCB::MOD_MASK_1 | XCB::MOD_MASK_CONTROL
  KeyMap[:AltShift]  = XCB::MOD_MASK_1 | XCB::MOD_MASK_SHIFT
  KeyMap[:Alt]       = XCB::MOD_MASK_1
  KeyMap[:Ctrl]      = XCB::MOD_MASK_CONTROL
end
