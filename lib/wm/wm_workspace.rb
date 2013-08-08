module WM
  # Simple hack providing multiple WorkSpace's (Desktops, etc)
  # Only core WorkSpace features are implementated
  # See, ./ws_ellipse.rb
  # For an example of extending.
  module WorkSpace
    # Just a default
    Space_NONE = 0
    
    # WorkSpaces
    Space_1 = 1
    Space_2 = 2
    Space_3 = 4
    Space_4 = 8
    
    Space_ALL = 16
    
    # Sets the current WorkSpace
    def set_workspace mask = Space_1
      @workspace = mask
    
      on_set_workspace mask
      
      mask
    end
    
    # Ensure Client's whose WorkSpace mask contains the current WorkSpace
    # Are displayed, Hide the rest
    def on_set_workspace mask
      show = clients.find_all do |c|
        c.get_workspace & mask > 0
      end
      
      clients.find_all do |c|
        !show.index(c)
      end.each do |c|
        c.unmap
      end
      
      show.each do |c|
        c.map()
      end    
    end
    
    # Ensure to unmap Client, c
    # If the Client's workspace mask does not contain the current WorkSpace
    def on_client_set_workspace c
      if c.get_workspace & get_workspace() > 0
      else
        c.unmap()
      end
    end
    
    # @return Integer, the current WorkSpace
    def get_workspace
      @workspace ||= Space_1
    end
    
    # @return Integer|NilClass, the index
    def get_workspace_index
      [
        Space_1,
        Space_2,
        Space_3,
        Space_4
      ].each_with_index do |s,i|
        if s == get_workspace()
          return i
        end
      end    
    end
    
    # Find the clients that match 'mask'
    # ie, c.get_workspace() & mask > 0
    # @return Array<WM::Client>
    def get_clients_for_workspace mask
      a = clients.find_all do |c|
        c.get_workspace() & mask > 0
      end
      
      return a
    end
    
    # Sets the workspace of the focused client
    def set_client_workspace mask
      c = get_focused_client()
      if c
        c.set_workspace mask
        on_client_set_workspace(c)
      end
    end
    
    def initialize *o
      super
      
      # Switch the current WorkSpace
      add_key_binding :Alt,      :"F1",  :set_workspace,Space_1
      add_key_binding :Alt,      :"F2",  :set_workspace,Space_2
      add_key_binding :Alt,      :"F3",  :set_workspace,Space_3
      add_key_binding :Alt,      :"F4",  :set_workspace,Space_4      
      
      # Send clients to WorkSpace
      add_key_binding :AltShift, :"F1",  :set_client_workspace,Space_1
      add_key_binding :AltShift, :"F2",  :set_client_workspace,Space_2   
      add_key_binding :AltShift, :"F3",  :set_client_workspace,Space_3
      add_key_binding :AltShift, :"F4",  :set_client_workspace,Space_4  
      
      # Viewable across all        
      add_key_binding :AltShift, :"F10", :set_client_workspace,Space_ALL          
    end
    
    # Call's `super`, then
    # Set the managed clients workspace to the current one
    def manage(w)
      super
      c = find_client_by_window(w)
      if c
        c.set_workspace(get_workspace)
      end
    end
    
    # Bring in some helpful methods
    module Client
      # set's the clients WorkSpace mask
      # mask may contain more than one WorkSpace
      def set_workspace mask
        @workspace = mask
      end
      
      # @return Integer, the client's WorkSpace mask
      def get_workspace
        @workspace ||= Space_NONE
      end
    end
  end
end
