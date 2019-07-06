local sky = include('meso/lib/sky')

engine.name = 'SimplePassThru'

chain = sky.Chain{
  sky.Logger{}
}

source = sky.Input{
  device = midi.connect(1),
  chain = chain
}

function init()
  source:enable()
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
  source:cleanup()
end