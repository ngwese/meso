local sky = include('meso/lib/sky/process')

-- for now focus on MIDI Mode 4 ("Mono Mode"), Omni Off, Mono

-- notes = {0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0} -- initial velocity (per-channel)

notes = {}

--
-- MPE Voice abstraction
--
local Note = {}
Note.__index = Note

local states = {
  INIT = 'init',
  START = 'start',
  TRACK = 'track',
  STOP = 'stop'
}

function Note.new(proto)
  local o = setmetatable(proto or {}, Note)
  -- initial values
  o.type = 'VOICE'
  o.state = states.INIT
  o.note = 0
  o.ch = 0
  o.vel = 0
  o.bend = 0
  o.pressure = 0
  o.cc74 = 0
  return o
end

function Note:on(event)
  --self.type = sky.types.NOTE_ON
  --tab.print(event)
  self.state = states.START
  if event ~= nil then
    self.note = event.note
    self.vel = event.vel
    self.ch = event.ch
  else
    self.note = 0
    self.vel = 127
    self.ch = 0
  end
  return self
end

function Note:off(event)
  --self.type = sky.types.NOTE_OFF
  self.state = states.STOP
  if event ~= nil then
    self.vel = event.vel
  else
    self.vel = 0
  end
  return self
end

function Note.process(event, output, state)
  local existing = notes[event.ch]
  if event.type == sky.types.NOTE_ON then
    if existing ~= nil then
      output(existing:off())
    end
    local new = Note.new():on(event) -- just enrich the parsed event
    notes[new.ch] = new
    output(new)
  elseif event.type == sky.types.NOTE_OFF then
    if existing ~= nil then
      existing:off(event)
    end
    output(existing)
  elseif event.type == sky.types.CHANNEL_PRESSURE then
    if existing ~= nil then
      existing.state = states.TRACK
      existing.pressure = event.val
      output(existing)
    end
  elseif event.type == sky.types.CONTROL_CHANGE then
    if event.cc == 74 and existing ~= nil then
      existing.state = states.TRACK
      existing.cc74 = event.val
      output(existing)
    end
  elseif event.type == sky.types.PITCH_BEND then
    if existing ~= nil then
      existing.state = states.TRACK
      existing.bend = event.val
      output(existing)
    end
  end
end

return Note