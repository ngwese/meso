local mu = require('musicutil')
local hs = require('awake/lib/halfsecond')
---local sky = include('sky/lib/prelude')

engine.name = 'Ceremony'

tuning_base = mu.note_num_to_freq(48)
chikari = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2}
tarafdar = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2, 2*16/15, 2*5/4, 2*4/3, 2*3/2}

which = 1
hz = 440

range = {1, 2, 3, 3, 3, 6, #chikari - 1} 
function key(n, z)
  if n == 2 and z == 1 then
    --which = math.random(#chikari - 1)
    which = math.random(range[math.random(#range)]) + 1
    local amp = (math.random(25) + 5) / 100
    hz = tuning_base * chikari[which]
    engine.start(which, hz, 1, amp, 0, 10, 1)
  end
  if n == 3 and z == 1 then
    local amp = (math.random(10) + 20) / 100
    which = 1
    hz = tuning_base * chikari[which]
    engine.start(which, hz, 1, amp, 0, 10, 1)
  end
end

function enc(n, d)
  if n == 2 then
    hz = hz + (d * 0.2)
    print(hz)
    engine.tune(which, hz)
  end
end

function redraw()
  screen.clear()
  screen.update()
end

function init()
  hs.init()
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
end

function cleanup()
  --source:cleanup()
end
