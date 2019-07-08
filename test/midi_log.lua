local sky = include('meso/lib/sky/process')

engine.name = 'SimplePassThru'

local chain = sky.Chain{
  -- output events as midi
  --sky.Output{ device = midi.connect(2) },
  sky.Logger{},
}

local source = sky.Input{
  device = midi.connect(2),
  chain = chain,
}

function init()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  source:cleanup()
end