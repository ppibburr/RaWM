$:.unshift File.join(File.dirname(__FILE__),"status","lib")
require "status"
require "status/defaults"

if ARGV.index("--list")
  puts "status.rb"
  puts "Here is a list of App's for the statusbar."

  apps.each_pair do |name,app|
    puts "  :#{name.to_s.ljust(25," ")}=> #{app.desc}"
  end
  
  puts "run: status.rb --show <app>"
  puts "For more info about a particular app"
  
  $exec = false
end

if ARGV[0] == "--show"
  $exec = false

  app = ARGV[1].gsub(/^\:/,'').to_sym
  app = apps()[app]
  
  puts "Info for: #{ARGV[1]}\n\n"
  puts "Description:"
  puts "  #{app.desc}"
  puts ""
  puts "Parameters:"
  app.properties.each do |k|
    puts "  :#{k}"
  end
end

app(:workspace).active_color = GREEN
app(:date).color             = WHITE
app(:network).set :width => 40, :essid_length => 10, :justify=>:center
app(:title).set   :width => 0.25, :color => WHITE
app(:disk).set    :disk => "/", :critical_free => 4
app(:bat).set     :width => 20, :critical_pct => 50, :justify=>:center
app(:volume).set  :width => 15, :justify=>:center

layout(:title,
       :workspace,
       :disk,
       :uptime,
       :network,
       :bat,
       :volume,
       :date)
