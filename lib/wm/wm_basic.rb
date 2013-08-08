require File.expand_path(File.join(File.dirname(__FILE__),"wm_client.rb"))

module WM
  class KeyBindingStore < Hash
    def add_key_binding mod,key,*o
      unless mod = sym2int(mod)  
        raise "KeyConversionError: Can not convert #{mod} to Integer"
      end
      
      unless key = sym2int(key)
        raise "KeyConversionError: Can not convert #{key} to Integer"      
      end
      
      m = self[mod] ||= {}
      m[key] = o
    end
    
    def sym2int q
      unless q.is_a?(Integer)
        return WM::KeyMap.find_by_symbol(q)
      end     
      
      return q
    end     
    
    def [] m
      if has_key?(m)
        return super
      end
      
      self[m] = {}
    end 
  end
  
  class Manager
    MANAGER_REPARENTING  = 0 # Will create a parent window for managed windows
    MANAGER_NON_REPARENT = 1 # ...
    
    # What type of manager are we ...
    MANAGE_MODE = MANAGER_NON_REPARENT
    
    # Events mask for the root window
    ROOT_WINDOW_EVENT_MASK = XCB::EVENT_MASK_SUBSTRUCTURE_REDIRECT | XCB::EVENT_MASK_SUBSTRUCTURE_NOTIFY |
                                        XCB::EVENT_MASK_ENTER_WINDOW |
                                        XCB::EVENT_MASK_LEAVE_WINDOW |
                                        XCB::EVENT_MASK_STRUCTURE_NOTIFY |
                                        XCB::EVENT_MASK_BUTTON_PRESS |
                                        XCB::EVENT_MASK_BUTTON_RELEASE | 
                                        XCB::EVENT_MASK_FOCUS_CHANGE |
                                        XCB::EVENT_MASK_PROPERTY_CHANGE      
        
    def self.client_class
      self::Client
    end
    
    # @return Array<Integer>, window id's currently existing
    def self.list_windows(conn,screen)
      tree_c = XCB::query_tree_unchecked(conn,
                    screen[:root]);

      tree_r = XCB::query_tree_reply(conn,
                    tree_c,
                    nil);

      # # Get the tree of the children windows of the current root window */
      if(!(wins = XCB::query_tree_children(tree_r)))
        printf("cannot get tree children");
        raise 
      end

      tree_c_len = XCB::query_tree_children_length(tree_r);
      wins.read_array_of_int(tree_c_len)
    end     
  
    attr_accessor :clients,:screen,:connection
    def initialize screen,conn
      @screen = screen
      @connection = conn
      
      @clients = []
      @key_bindings = KeyBindingStore.new
    end
    
    # Apply attributes to the 'root' window to get events rolling 
    def init
      window_root = screen[:root];
      mask        = XCB::CW_EVENT_MASK;
      values      = ary2pary([ ROOT_WINDOW_EVENT_MASK]);
     
      cookie = XCB::change_window_attributes_checked(connection, window_root, mask, values);
      error = XCB::request_check(connection, cookie);
      XCB::flush(connection);
    
      if error.to_ptr != FFI::Pointer::NULL
        on_abort(0)
      end
       
      manage_existing()  
      
      @key_bindings.each_pair do |mod,v|
        v.each_pair do |key,vv|        
          XCB::grab_key(connection, 1, screen[:root], mod, key, XCB::GRAB_MODE_ASYNC, XCB::GRAB_MODE_ASYNC);
        end
      end
      
      XCB::flush connection      
    end
    
    ABORT = {0=>"Manager Running",1=>"SIGINT recieved",2=>"EVENT LOOP Error"}
    
    # Ensure proper exiting
    def on_abort code,error=nil
      case code
      when 0
        XCB::set_input_focus(connection, XCB::NONE, XCB::INPUT_FOCUS_POINTER_ROOT, XCB::CURRENT_TIME);
        XCB::flush(connection)
        puts "Eh? Probally another manger running. Abort ..."   
        XCB::disconnect(connection)
        exit(1)
      when 2
        XCB::set_input_focus(connection, XCB::NONE, XCB::INPUT_FOCUS_POINTER_ROOT, XCB::CURRENT_TIME);
        XCB::flush(connection)   
        puts "ABORT CODE: #{code}, #{ABORT[code]}\n#{error}"
        puts error.backtrace.join("\n") if error
        XCB::disconnect(connection)
        exit(1) 
      else
        XCB::set_input_focus(connection, XCB::NONE, XCB::INPUT_FOCUS_POINTER_ROOT, XCB::CURRENT_TIME);
        XCB::flush(connection)   
        puts "ABORT CODE: #{code}, #{ABORT[code]}"
        XCB::disconnect(connection)
        exit(1)      
      end
    end
    
    # @return true, if reparenting
    def is_reparenting?
      self.class::MANAGE_MODE == MANAGER_REPARENTING
    end
    
    # @param Integer, w the window to manage
    def manage w
      # do not re-manage a managed window
      if !@clients.find do |c| c.window.id == w or (is_reparenting?() and c.frame_window.id == w) end
        # manage the window unless it's 'transient_for' another
        @clients << self.class.client_class.new(w,self)  unless tw=Window.new(connection,w).transient_for
      
        # Handle transient window
        if tw
          manage_transient(w,tw)
        end
      end
    end
    
    # TODO: handle better
    #
    # @param w,  the window to manage
    # @param tw, the window w is 'transient_for'
    def manage_transient w,tw
      win=Window.new(connection,w)
      win.map()
      win.raise
      win.focus  
    end
    
    # Done at startup
    # Find existing windows to manage
    def manage_existing()   
      Manager.list_windows(connection,screen).map do |w|
        manage(w)
      end
     
      XCB::flush(connection)
    end
    
    CREATE_WINDOW_MASK = XCB::CW_BACK_PIXEL |
               XCB::CW_BORDER_PIXEL |
               XCB::CW_BIT_GRAVITY |
               XCB::CW_WIN_GRAVITY |
               XCB::CW_OVERRIDE_REDIRECT |
               XCB::CW_EVENT_MASK |
               XCB::CW_COLORMAP
    
    # creates a window at x,y of width w and height h with a border of bw
    def create_window x,y,w,h,bw
      window = XCB::generate_id(connection);
      a= [connection, XCB::WINDOW_CLASS_COPY_FROM_PARENT, window, screen[:root],
              x,y,w,h,
              bw, XCB::WINDOW_CLASS_COPY_FROM_PARENT, XCB::WINDOW_CLASS_COPY_FROM_PARENT,
              CREATE_WINDOW_MASK,
              ary2pary([
                screen[:black_pixel],
                screen[:black_pixel],
                XCB::GRAVITY_NORTH_WEST,
                XCB::GRAVITY_NORTH_WEST,
                1,
                Client::FRAME_SELECT_INPUT_EVENT_MASK,
                0
              ])]
      XCB::create_window(*a);
              
      Window.new(connection,window).map()
      XCB::flush(connection)                  
      window
    end
    
    # finds the client representing the window w
    # @return Client|NilClass, a Client when w matches the 'window' of the client or its 'frame' (if reparenting)
    def find_client_by_window(w)
      @clients.find do |c|
        c.window.id == w or (is_reparenting?() and c.frame_window.id == w )
      end
    end
    
    def viewable_clients
      clients.find_all do |c|
        c.get_window.is_mapped?
      end
    end
    
    # Find the client for window w and call it's destroy() method
    # @param Integer, w, the window id to find the client for
    def unmanage(w)
      c = find_client_by_window w
      if c
        c.destroy()
        return true
      else
        return false
      end
    end
    
    def add_key_binding m,k,*o
      @key_bindings.add_key_binding m,k,*o
    end    
    
    # call init()
    # Loop over events and handle them
    def main
      init()
    
      loop do
        while (evt=XCB::wait_for_event(connection)).to_ptr != FFI::Pointer::NULL;
          handle_event(evt)
        end
      end
      
    rescue => e
      on_abort(2,e)
    end
    
    def handle_event evt
	  return unless on_before_event(evt)
	  
	  case evt[:response_type] & ~0x80
	  when XCB::KEY_PRESS
		evt = XCB::KEY_PRESS_EVENT_T.new(evt.to_ptr)
		on_key_press(evt)
		
	  when XCB::KEY_RELEASE
		evt = XCB::KEY_RELEASE_EVENT_T.new(evt.to_ptr)
		on_key_release(evt)	
		
	  when XCB::BUTTON_PRESS
		evt = XCB::BUTTON_PRESS_EVENT_T.new(evt.to_ptr)
		on_button_press(evt)
		
	  when XCB::BUTTON_RELEASE
		evt = XCB::BUTTON_RELEASE_EVENT_T.new(evt.to_ptr)
		on_button_release(evt)				
		
	  when XCB::ENTER_NOTIFY
		evt = XCB::ENTER_NOTIFY_EVENT_T.new(evt.to_ptr)
	
        on_enter_notify(evt)
		
	  when XCB::LEAVE_NOTIFY
		evt = XCB::LEAVE_NOTIFY_EVENT_T.new(evt.to_ptr)
	
        on_leave_notify(evt)

	  when XCB::UNMAP_NOTIFY
		evt = XCB::UNMAP_NOTIFY_EVENT_T.new(evt.to_ptr)
	  
        on_unmap_notify(evt)
		
	  when XCB::CONFIGURE_NOTIFY
		evt = XCB::CONFIGURE_NOTIFY_EVENT_T.new(evt.to_ptr)
				
		on_configure_notify(evt)
		 
	  when XCB::CONFIGURE_REQUEST
		evt = XCB::CONFIGURE_REQUEST_EVENT_T.new(evt.to_ptr)
		  
		on_configure_request(evt)
		       
	  when XCB::MAP_REQUEST
		evt = XCB::MAP_REQUEST_EVENT_T.new(evt.to_ptr)
	
		on_map_request(evt)
		   
	  when XCB::CLIENT_MESSAGE 
		evt = XCB::CLIENT_MESSAGE_EVENT_T.new(evt.to_ptr)
        on_client_message(evt)
        
	  when XCB::DESTROY_NOTIFY
		evt = XCB::DESTROY_NOTIFY_EVENT_T.new(evt.to_ptr)

		on_destroy_notify(evt)  
	  end
		  
	  on_after_event(evt)
	
	  CLib::free evt.to_ptr 
	  XCB::flush(connection)    
    end    
    
    # Called before default event handling
    # When overiding, all return values except false,nil
    # allow default event handling
    #
    # @param XCB::GENERIC_EVENT_T, e, the event
    def on_before_event(e)
      return true
    end
    
    # Called after default event handling
    #
    # @param XCB::GENERIC_EVENT_T, e, the event
    def on_after_event(e)
    
    end
    
    #
    # Events.
    # Overide these.
    #
    
	def on_key_press e
	  @key_bindings.each_pair do |mod,v|
		next unless e[:state] == mod
		p [:MOD,mod]
		v.each_pair do |key,v|
		  if key == e[:detail]
		    send *v
		    return e
		  end
		end
	  end
	  
	  return e
	end
	
	def on_key_release(evt)
	
	end
	
	def on_button_press(evt)
	
	end
	
	def on_button_release(evt)
	
	end
	
	def on_configure_notify(evt)
      if c = find_client_by_window(evt[:window])
	    c.on_configure_notify(evt)
	  end	
	end
	
	def on_configure_request(evt)
      if c = find_client_by_window(evt[:window])
	    c.on_configure_request(evt)
	  end
	end
	
	def on_map_request(evt)
      if c = find_client_by_window(evt[:window])
	    c.on_map_request(evt)
	  else 
	    manage(evt[:window]) 
	  end
	end
	
	def on_unmap_notify(evt)
	  if c = find_client_by_window(evt[:window])
	    c.on_unmap_notify(evt)
	  end
	end
	
	def on_enter_notify(evt)
	  if c = find_client_by_window(evt[:event])
	    c.on_enter_notify(evt)
  	  end
	end
	
	def on_leave_notify(evt)
	  if c = find_client_by_window(evt[:event])
	    c.on_leave_notify(evt)
	  end
	end
	
	def on_client_message(evt)
	
	end   
	
	def on_destroy_notify evt
	  WM::log :debug do
	    w      = evt[:window]
	    client = find_client_by_window(w)
	    name   = `xdotool getwindowname #{w}`
	    
	    "in on_destoy_notify(), Window: #{w}, Name: #{name}, Client: #{client}"
	  end
	  
      unmanage(evt[:window])	
	end 
  end

  # Base for reparenting window managers  
  class ReparentingManager < Manager
    MANAGE_MODE = Manager::MANAGER_REPARENTING
  end  
end






