module WM
  # Handle things specific to the window layout of an elliptical manager
  # In regards to WorkSpace's
  module EllipseWS
    include WM::WorkSpace
  
    # perform a draw using the WorkSpace's 'master' as the client to be active
    # mask is intended to be a single WorkSpace, however it should render multiple
    # but it is not tested
    def on_set_workspace mask
      super
      draw((@ws_active ||= {})[mask] || nil)
    end
    
    # Update the current WorkSpace 'master'
    def set_active(*o)
      super
      (@ws_active ||= {})[get_workspace()] = o.first
    end
    
    # When clients change WorkSpace's
    # They become the 'master', for the WorkSpace's contained in the mask
    def on_client_set_workspace c
      super
      
      [
        Space_1,
        Space_2,
        Space_3,
        Space_4
      ].each do |mask|
        if c.get_workspace() & mask > 0
          (@ws_active ||= {})[mask] = c
        end
      end
      
      draw c == @active ? nil : @active
    end  
  end
end
