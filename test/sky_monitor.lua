local sky = include('meso/lib/sky/process')

engine.name = 'SimplePassThru'

local chain = sky.Chain{
  -- track currently held notes, emit event when it changes
  sky.Held{},
  -- consume held note events, emit event with pattern built from held notes
  sky.Pattern{ style = 'up' },
  -- play arpeggio from the pattern, driven by clock events
  sky.Arp{},
  -- output events as midi
  sky.Output{ device = midi.connect(2) },
  --sky.Logger{},
}

local source = sky.Input{
  device = midi.connect(1),
  chain = chain,
}

local clk = sky.Clock{
  interval = sky.bpm_to_sec(120, 4),
  chain = chain,
}

function init()
  clk:start()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:cleanup()
  source:cleanup()
end