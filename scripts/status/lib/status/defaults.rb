require File.join(File.dirname(__FILE__),"sysinfo.rb")

app(:disk, :disk, :critical_free) do
  self.disk  ||= "/"
   
  i = 1 + 2
  amt = `df #{disk}`.split("\n")[1].strip.split(' ')[i].to_i / 1024.0 / 1024
  
  critical(amt,critical_free,"#{amt.round(2)} GB")
end.desc = "Disk usage info"

app(:date) do
  Time.now.strftime("%A %b %d %Y %H:%M")
end.desc = "Date"

app(:uptime) do
  u = uptime
  "UP: #{u[:time]}, LOAD #{u[:load]}"
end.desc = "uptime"

app(:title) do
  `xdotool getwindowname #{Status[:focused]}`.strip
end.desc = "The name of the focused window"

app(:bat, :critical_pct) do
  self.critical_pct ||= 50

  b = battery()
  i = [false,true].index(b[:state])
  
  msg = ["Discharging","Charging","Full"]
  
  "#{critical(b[:state],0,msg[b[:state]+1])} #{critical(v=(b[:percent]*100).round(2),critical_pct,"#{v}%")}" 
end.desc = "Battery info"

app(:workspace, :active_color) do
  active = Status[:workspace]
  avail  = Status[:workspaces] ||= 4
  
  (1..avail).map do |i|
    i == active ? "#{start_color(active_color())}[#{colorize(RED,i.to_s)}]#{stop_color()}" : "#{i}"
  end.join(" ")
end.desc = "Active workspace"

app(:volume) do
  v = volume()
  
  "Volume: "+critical(v[:state],1,"#{v[:state] > 0 ? (v[:level]*100).round(2).to_s+"%" : "OFF"}")
end.desc = "Volume info"

app(:network, :essid_length, :critical_pct, :essid_color, :ip_color) do
  self.essid_length ||= -1
  self.critical_pct ||= 65
  self.essid_color  ||= BLUE
  self.ip_color     ||= WHITE

  n = network()
  
  next start_color(color_bad)+"Disconnected"+stop_color() unless n[:state] > 0
  
  if n[:wireless]
    essid = n[:essid][0..essid_length]
  
    next "#{n[:name]}: #{colorize(essid_color,essid)} #{critical(pct=n[:signal]*100,critical_pct,"#{pct}%")} #{colorize(ip_color,n[:addr])}"
  else
    next "#{n[:name]}: #{colorize(WHITE,n[:addr])}"
  end
end.desc = "Active network info"
