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

class App
  @instances = {}
  class << self
    attr_reader :instances
  end
  
  attr_accessor :width,:color,:justify
  def initialize name,&b
    @render = b
    @name = name
    ::App.instances[name] = self
  end
  
  def render
    str = ""
    if color
      str = start_color(color) + instance_eval(&@render) + stop_color()
    else
      str = instance_eval &@render
    end
    
    if width
      i = -1
      f = []
      
      str.scan(/\^fg.*?\)/) do |t|
        f << t
      end
      
      str=str.split(/\^fg.*?\)/).join(fmt="%FORMAT")
      
      adj_w = width+(f.length-1)*fmt.length

      str = str[0..adj_w-1]
      str = str.send @justify||=:ljust, adj_w, " "
      
      i = -1
      str = str.split(fmt).map do |q|
        i+=1
        q+f[i]
      end.join+f.last
    end
    
    return str
  end
  
  def set *o
    h = o[0]
    h.each_pair do |k,v|
      send :"#{k}=",v
    end
  end
  
  def start_color c
    (@colors||=[]).push c="^fg(#{c})"
    c
  end
  
  def stop_color
    closed = @colors.pop
    if @colors.empty?
      "^fg()"
    else
      @colors.last
    end
  end
  
  def colorize c,text
    start_color(c)+
    text+
    stop_color()
  end
end

def app name,*accessors,&b
  if b
    kls = Class.new(App)
    kls.class_eval do
      attr_accessor *accessors
    end
    
    return kls.new(name,&b)
  end
  
  return App.instances[name]
end

def layout(*order)
  @order = order.map do |name|
    app(name)
  end
end

FONT_WIDTH = `dzen2-textwidth fixed a`.strip.to_i
MAX_CHARS  = (Status[:width] / FONT_WIDTH.to_f).floor

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

app :disk, :disk, :field do
  self.field ||= :free
  self.disk  ||= "/"
   
  i = [:used,:free].index(field) + 2
  amt = `df #{disk}`.split("\n")[1].strip.split(' ')[i].to_i / 1024.0 / 1024
  whole,part = "#{amt}".split(".")
  part = part[0..1]
  "#{whole}.#{part} GB"
end

app :date do
  Time.now.strftime("%A %b %d %Y %H:%M")
end

app :title do
  `xdotool getwindowname #{Status[:focused]}`.strip
end

app :workspace, :active_color do
  active = Status[:workspace]
  avail  = Status[:workspaces] ||= 4
  
  (1..avail).map do |i|
    i == active ? "#{start_color(active_color())}[#{colorize(RED,i.to_s)}]#{stop_color()}" : "#{i}"
  end.join(" ")
end

app(:title).width = 55
app(:title).color = WHITE
app(:workspace).active_color = GREEN
app(:disk).set :disk => "/", :field=>:free
app(:date).color = WHITE

layout :title,
       :workspace,
       :disk,
       :date

dzen = IO.popen("dzen2 -ta l -fn fixed","w")

loop do
  Status.update()
  dzen.puts dump()
  sleep 0.33
end
