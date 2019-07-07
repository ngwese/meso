--
-- soft midi thru test
--

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

xin = midi.connect(1)
xout = midi.connect(2)

xin.event = function(data)
  event_count = event_count + 1
  xout:send(data)
end

--
-- lifecycle
--

function init()
  c:start()
end

function cleanup()
  c:stop()
end
