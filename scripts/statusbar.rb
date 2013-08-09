# statusbar.rb
#
# launch a dzen2 status bar filled with the foucused window name and i3status output
#
# ppibburr tulnor33@gmail.com

i3s  = IO::popen("i3status")
dzen = IO::popen("dzen2 -ta l","w")

while s=i3s.gets
  buff = File.open("#{ENV['HOME']}/.wm_status.txt","r").read.strip
  active = (buff.scan(/focused\: ([0-9]+)/)[0]||=[])[0]
  active = `xdotool getwindowname #{active}`.strip
  active = (0..35).map do |i|
    active[i] || " "
  end.join
  workspace = (buff.scan(/workspace\: ([0-9]+)/)[0]||=[])[0]
  ws_list = [1,2,3,4].map do |q|
    q=q.to_s
    q==workspace ? "[#{q}]" : q
  end.join(" ")
  dzen.puts "#{active} | #{ws_list} | #{s}"
end
