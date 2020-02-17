local mu = require('musicutil')
local hs = require('awake/lib/halfsecond')
local SitarEngine = require('meso/lib/sitar_engine')
local sky = include('meso/lib/sky/process')
local mpe = include('meso/lib/sky/mpe')

engine.name = 'Sitar'

tuning_base = mu.note_num_to_freq(48)
chikari = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2}
tarafdar = {1, 16/15, 5/4, 4/3, 3/2, 8/5, 15/8, 2, 2*16/15, 2*5/4, 2*4/3, 2*3/2}


function render(event, output, state)
--  local x = util.linlin(0, 127, 0, 64, event.num)
  local x = event.note
  local y = util.linlin(0, 127, 64, 0, event.cc74)
  local r = util.linlin(0, 127, 2, 15, event.pressure)
  screen.clear()
  --screen.move(10, 10)
  --screen.text(event.pressure)
  screen.circle(x, y, r)
  screen.close()
  screen.stroke()
  screen.update()
end

chain = sky.Chain{
  -- output events as midi
  --mpe.Process{},
  sky.Logger{},
  --sky.Func(render)
}

local source = sky.Input{
  name = "ContinuuMini",
  chain = chain,
}

local source2 = sky.Input{
  name = "Lightpad BLOCK",
  chain = chain,
}


function key(n, z)
  if n == 2 and z == 1 then
    local which = math.random(#chikari - 1)
    local amp = (math.random(25) + 5) / 100
    engine.pluck(which, amp)
  end
  if n == 3 and z == 1 then
    local amp = (math.random(10) + 20) / 100
    engine.pluck(0, amp)
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
  SitarEngine.init_tuning(chikari, tarafdar, tuning_base)
  SitarEngine.add_params()
end

function cleanup()
  source:cleanup()
end
