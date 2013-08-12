require File.join(File.dirname(__FILE__),"status","app.rb")

# Non true, don't luanch the bar
$exec = true

RED   = "#FF0000"
GREEN = "#00FF00"
BLUE  = "#0000FF"
BLACK = "#000000"
WHITE = "#FFFFFF"

Status = {}

def Status.update
  open("#{ENV["HOME"]}/.wm_status.txt").readlines.each do |l|
    k,v = l.strip.split(":").map do |q| q.strip end

    if v =~ /^[0-9]+$/
      v = v.to_i
    end

    Status[k.to_sym] = v
  end
end

Status.update()

FONT_WIDTH = `dzen2-textwidth fixed a`.strip.to_i
MAX_CHARS  = (Status[:width] / FONT_WIDTH.to_f).floor

def apps()
  App::instances
end

def app name,*accessors,&b
  if b
    kls = Class.new(App)
    kls.class_eval do
      attr_accessor *accessors
    end
    
    ins = kls.new(name,&b)
    
    ins.properties = accessors
    
    return ins
  end
  
  return App.instances[name]
end

def layout(*order)
  @order = order.map do |name|
    app(name)
  end
end

def dump()
  @order ||= ::App.instances.map do |k,v| v end

  chars = 0
  
  @order.map do |app|
    bool = nil
    if @order.last == app
      bool = true
      app.justify = :rjust
      app.width   = MAX_CHARS - chars+1
    end
    
    str = app.render()
    
    chars += str.gsub(/\^fg.*?\)/,'').length
    
    unless bool
      chars += 4
    end
    
    str
  end.join(" | ")
end

def colorize c,text,bg=false
  "^fg(#{c})#{text}^fg()"
end

at_exit do
  next unless $exec

  dzen = IO.popen("dzen2 -ta l -fn fixed","w")

  loop do
    Status.update()
    dzen.puts dump()
    sleep 0.33
  end
end
