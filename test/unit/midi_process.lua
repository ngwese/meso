lu = include('meso/lib/ext/luaunit')
mp = include('meso/lib/midi_process')

-- TestInput = {}

TestChain = {}

function TestChain:testThruChainRunIsNoop()
  local c = mp.Chain{ mp.Thru() }
  local evts = { mk_clock(), mk_note_on(1, 72, 127) }
  local out = c:run(evts)

  lu.assertEquals(out, evts)
end

function TestChain:testThruChainBypassedIsEmpty()
  local c = mp.Chain{ mp.Thru() }
  c.devices[1].bypass = true

  local evts = { mk_start(), mk_clock(), mk_stop() }
  local out = c:run(evts)

  lu.assertEquals(out, {})
end

function TestChain:testMultiThruIsNoop()
  local c = mp.Chain{ mp.Thru(), mp.Thru(), mp.Thru() }
  local evts = { mk_note_on(1, 89, 112), mk_control_change(1, 7, 100), mk_note_off(1, 89, 4) }

  local out = c:run(evts)

  lu.assertEquals(out, evts)
end

function TestChain:testSingleInputMultiOutput()
  local Double = {}
  Double.__index = Double

  function Double.new()
    return setmetatable({}, Double)
  end

  function Double:process(event, output)
    output(event)
    output(event)
  end

  local e1 = mk_note_on(1, 34, 127)
  local e2 = mk_clock()
  local e3 = mk_stop()

  local expect = { e1, e1, e2, e2, e3, e3 }

  local c = mp.Chain{ Double.new() }
  local out = c:run{ e1, e2, e3 }

  lu.assertEquals(out, expect)

  c = mp.Chain{ Double.new(), mp.Thru(), Double.new() }
  out = c:run{ e1, e2 }
  expect = { e1, e1, e1, e1, e2, e2, e2, e2 }
  lu.assertEquals(out, expect)
end

-- TestBehavior = {}

-- TestThru = {}

os.exit(lu.LuaUnit.run())