def volume
  v    = {}
  buff = `amixer get Master`
  
  v[:state] = case buff
  when /\[on\]$/
    1
  else
    0
  end
  
  v[:level] = buff.scan(/([0-9]+)%/)[0][0].to_i/100.0
  
  return v
end

def uptime
  u = {}
  buff = `uptime`
  
  begin
    u[:time] = buff.scan(/up (.*), .*[0-9]+ users/)[0][0]
  rescue
  end
  
  u[:load] = buff.scan(/average: (.*)/)[0][0].split(" ").last.strip.to_f.round(2)

  return u
end

require 'time'

def battery
  b = {}
  buff = `acpi -bat`

  b[:state]   = case buff
  when /Discharging/
    -1
  when /Charging/
    0
  when /Full/
    1
  else
    -1
  end
    
  b[:percent] = buff.scan(/([0-9]+)\%/)[0][0].to_i/100.0;
  
  begin
    b[:time]    = Time.now + (Time.parse(buff.scan(/([0-9]+:[0-9]+:[0-9]+)/)[0][0]) - Time.parse("00:00:00"))
  rescue
  end
  
  return b
end

def network
  raise "Must be root" unless Process.uid == 0

  iface = {}

  buff = `dbus-send --system --print-reply --dest=org.wicd.daemon /org/wicd/daemon org.wicd.daemon.GetCurrentInterface`
  iface[:name] = buff.scan(/string "(.*)"/)[0][0]
  
  buff = `dbus-send --system --print-reply --dest=org.wicd.daemon /org/wicd/daemon org.wicd.daemon.GetWirelessInterface`
  wiface = buff.scan(/string "(.*)"/)[0][0]
  
  if iface[:name] == ""
    if wiface != ""
      iface[:name] = wiface
      iface[:wireless] = true
    end
  else
    iface[:wireless] = iface[:name] == wiface
  end

  iface[:name] = wiface if wiface != "" and iface[:name] == ""
  
  return {:state=>0} if iface[:name] == ""
  
  begin
    iface[:addr] = `ip addr show #{iface[:name]}`.scan(/inet (.*?)\//)[0][0]
  rescue
    return {:state=>0}
  end
  
  iface[:state] = 1
  
  if iface[:wireless]
    buff = `dbus-send --system --print-reply --dest=org.wicd.daemon /org/wicd/daemon/wireless org.wicd.daemon.wireless.GetCurrentSignalStrength`
    iface[:signal] = (buff.scan(/int32 ([0-9]+)/)[0][0].to_i/100.0).round(2)
    iface[:essid]  = `iwconfig eth1 | grep eth1 | sed s/.*ESSID://`.scan(/"(.*)"/)[0][0]
  end

  return iface
end

