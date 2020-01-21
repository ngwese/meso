local mu = require('musicutil')
local hs = require('awake/lib/halfsecond')
SitarEngine = require('meso/lib/sitar_engine')

engine.name = 'Sitar'

tuning_base = mu.note_num_to_freq(48)
chikari = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2}
tarafdar = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2, 2*16/15, 2*5/4, 2*4/3, 2*3/2}

function key(n, z)
  if n == 2 and z == 1 then
    local which = math.random(#chikari) - 1
    local amp = (math.random(25) + 5) / 100
    engine.pluck(which, amp)
  end
  if n == 3 and z == 1 then
    local amp = (math.random(10) + 20) / 100
    engine.pluck(0, amp)
  end
end

function init()
  hs.init()
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  SitarEngine.init_tuning(chikari, tarafdar, tuning_base)
  SitarEngine.add_params()
end