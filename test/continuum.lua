-- continuum test

local tu = require "tabutil"
local powermate = include("meso/lib/powermate")
local continuum = include("meso/lib/continuum")

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

cm = continuum.connect(1)
cm.device.event = function(data)
  local e = midi.to_msg(data)
  if e.ch == 16 then
    tu.print(e)
  end
  event_count = event_count + 1
end

pm = powermate.connect(1)
pm.key = function(num, value)
  print("key: ", num, value)
end
pm.enc = function(num, delta)
  print("enc: ", num, delta)
end

-- function enc(num, delta)
--   print("[enc]: ", num, delta)
-- end

-- function key(num, z)
--   print("[key]: ", num, z)
-- end

--
-- lifecycle
--

function init()
  --c:start()
end

function cleanup()
  --c:stop()
end
