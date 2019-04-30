-- continuum test

local tu = require "tabutil"
local continuum = include("ngwese/lib/continuum")

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
-- handlers
--

local midi_handler = function(data)
  local e = midi.to_msg(data)
  tu.print(e)
  event_count = event_count + 1
end

cm = continuum.connect(1)
cm.device.event = midi_handler

--
-- lifecycle
--

function init()
  --c:start()
end

function cleanup()
  --c:stop()
end
