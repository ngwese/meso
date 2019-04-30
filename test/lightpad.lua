-- roli block test
local tu = require 'tabutil'


local event_count = 0

function report()
  print(event_count, "msg/s")
  event_count = 0
end

c = metro.init()
c.time = 1
c.count = -1
c.event = report

--
-- midi
--
local midi_handler = function(data)
  --local e = midi.to_msg(data)
  --tu.print(e)
  event_count = event_count + 1
end

m = midi.connect(1)
m.event = midi_handler

m = midi.connect(2)
m.event = midi_handler

--
-- hid
--
local hid_handler = function(type, code, value)
  print("hid", type, code, value)
end

h = hid.connect(1)
h.event = hid_handler


local midi_added = function(dev)
  print("added", dev)
end

local midi_removed = function(dev)
  print("removed", dev)
end

function init()
  print("init begin")
  midi.add(midi_added)
  midi.remove(midi_removed)
  c:start()
  print("init end")
end

function cleanup()
  c:stop()
end

