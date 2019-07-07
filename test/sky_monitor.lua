local sky = include('meso/lib/sky')

engine.name = 'SimplePassThru'

local chain = sky.Chain{
  sky.Logger{},
  sky.Held{
    -- debug = true,
  },
  sky.Pattern{},
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
  source:enable()
  clk:enable()
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