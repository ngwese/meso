local Event = include('meso/lib/sky/event')

-- for now focus on MIDI Mode 4 ("Mono Mode"), Omni Off, Mono

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
  o.bend = 0.0
  o.pressure = 0
  o.cc74 = 0
  return o
end

function Note:on(event)
  --self.type = Event.types.NOTE_ON
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
  --self.type = Event.types.NOTE_OFF
  self.state = states.STOP
  if event ~= nil then
    self.vel = event.vel
  else
    self.vel = 0
  end
  return self
end

local Process = {}
Process.__index = Process

function Process.new(proto)
  local o = setmetatable(proto or {}, Process)
  -- defaults
  o.notes = {}
  o.bypass = false
  return o
end

function Process:process(event, output, state)
  if self.bypass then
    output(event)
  end

  local existing = self.notes[event.ch]
  if event.type == Event.types.NOTE_ON then
    if existing ~= nil then
      output(existing:off())
    end
    local new = Note.new():on(event) -- just enrich the parsed event
    self.notes[new.ch] = new
    output(new)
  elseif event.type == Event.types.NOTE_OFF then
    if existing ~= nil then
      existing:off(event)
    end
    output(existing)
  elseif event.type == Event.types.CHANNEL_PRESSURE then
    if existing ~= nil then
      existing.state = states.TRACK
      existing.pressure = event.val
      output(existing)
    end
  elseif event.type == Event.types.CONTROL_CHANGE then
    if event.cc == 74 and existing ~= nil then
      existing.state = states.TRACK
      existing.cc74 = event.val
      output(existing)
    end
  elseif event.type == Event.types.PITCH_BEND then
    if existing ~= nil then
      existing.state = states.TRACK
      existing.bend = Event.to_bend_range(event.val)
      existing.note = util.clamp(0, 127, existing.note + (10 * existing.bend))
      output(existing)
    end
  end
end

return {
  Note = Note.new,
  Process = Process.new,
}
