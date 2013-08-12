class App
  @instances = {}
  class << self
    attr_reader :instances
  end
  
  attr_accessor :width,:color,:justify,:color_good,:color_bad,:properties,:desc
  def initialize name,&b
    @color_good = GREEN
    @color_bad  = RED
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
      if width.is_a?(Float)
        self.width = (MAX_CHARS * width).floor
      end
    
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
        q+f[i].to_s
      end.join+f.last.to_s
    end
    
    return str
  end
  
  def set *o
    h = o[0]
    h.each_pair do |k,v|
      send :"#{k}=",v
    end
  end
  
  def critical val,min,str
    str=str.to_s
    
    if val >= min
      return start_color(color_good)+str+stop_color()
    else
      return start_color(color_bad)+str+stop_color()
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
