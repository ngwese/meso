local sky = include('meso/lib/sky')

engine.name = 'SimplePassThru'

-- local output = sky.output{
--   device = midi.connect(2),
-- }

-- local sw = sky.Chain{
--   sky.Switcher{
--     sky.Output{
--       device = midi.connect(2),
--     },
--     sky.Output{
--       device = midi.connect(3),
--     },
--     sky.Logger{},
--   },
-- }
 
local chain = sky.Chain{
  sky.Logger{},
  sky.Output{
    device = midi.connect(2),
  },
  -- sky.Held{
  --   debug = true,
  -- },
  -- sky.Pattern{},
}

local source = sky.Input{
  device = midi.connect(1),
  chain = chain,
}

local clk = sky.Clock{
  interval = sky.bpm_to_sec(120),
  chain = chain,
}




function init()
  -- clk:start()
end

function key(n, z)
end

function enc(n, d)
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:cleanup()
  source:cleanup()
end