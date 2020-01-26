-- midi helper module
-- @module sky
-- @alias ski

local Deque = include('meso/lib/container/deque')

--
-- module constants
--

local types = {
  -- defined in lua/core/midi.lua
  NOTE_ON = 'note_on',
  NOTE_OFF = 'note_off',
  CHANNEL_PRESSURE = 'channel_pressure',
  KEY_PRESSURE = 'key_pressure',
  PITCH_BEND = 'pitchbend',
  CONTROL_CHANGE = 'cc',
  PROGRAM_CHANGE = 'program_change',
  CLOCK = 'clock',
  START = 'start',
  STOP = 'stop',
  CONTINUE = 'continue',

  -- extended types
}

-- invert type table for printing
local function invert(t)
  local n = {}
  for k, v in pairs(t) do n[v] = k end
  return n
end

local type_names = invert(types)

--
-- event creation (compatible with midi:send(...))
--

local function mk_note_on(note, vel, ch)
  return { type = types.NOTE_ON, ch = ch or 1, note = note, vel = vel }
end

local function mk_note_off(note, vel, ch)
  return { type = types.NOTE_OFF, ch = ch or 1, note = note, vel = vel }
end

local function mk_channel_pressure(val, ch)
  return { type = types.CHANNEL_PRESSURE, ch = ch or 1, val = val }
end

local function mk_key_pressure(val, ch)
  return { type = types.KEY_PRESSURE, ch = ch or 1, val = val }
end

local function mk_pitch_bend(val, ch)
  return { type = types.PITCH_BEND, ch = ch or 1, val = val }
end

local function mk_program_change(val, ch)
  return { type = types.PROGRAM_CHANGE, ch = ch or 1, val = val }
end

local function mk_control_change(cc, val, ch)
  return { type = types.CONTROL_CHANGE, ch = ch or 1, cc = cc, val = val }
end

local function mk_clock(stage, ch)
  return { type = types.CLOCK, ch = ch or 1, stage = stage }
end

local function mk_start(ch)
  return { type = types.START, ch = ch or 1 }
end

local function mk_stop(ch)
  return { type = types.STOP, ch = ch or 1 }
end

local function mk_continue(ch)
  return { type = types.CONTINUE, ch = ch or 1 }
end

--
-- helper functions
--

-- convert midi note number to frequency in hz
-- @param num : integer midi note number
local function to_hz(num)
  local exp = (num - 21) / 12
  return 27.5 * 2^exp
end


local MIDI_BEND_ZERO = 1 << 13
-- convert midi pitch bend to [-1, 1] range
-- @param value : midi pitch bend value (assumed to be 14 bit)
local function to_bend_range(value)
  local range = MIDI_BEND_ZERO
  if value > MIDI_BEND_ZERO then
    range = range - 1
  end
  return (value - MIDI_BEND_ZERO) / range
end

-- pack midi channel and note values into a numeric value useful as an id or key
-- @param ch : integer channel number
-- @param num : integer note number
local function to_id(ch, num)
  return ch << 8 | num
end

-- convert midi event object to a readable string
-- @param event : event object (as created by the mk_* functions)
local function to_string(event)
  local tn = type_names[event.type]
  local e
  if tn == nil then
    -- unknown/custom event type
    e = "custom " .. event.type
  else
    e = "event " .. tn
  end

  for k,v in pairs(event) do
    if k ~= "type" then
      e = e .. ', ' .. k .. ' ' .. v
    end
  end
  return e
end

-- return true if str starts with start (string)
-- @param str : the string to test
-- @param start : the string appearing at the beginning
local function starts_with(str, start)
  return str:sub(1, #start) == start
end

-- convert bpm value to equivalent interval in seconds
-- @param bpm : beats per minute
-- @param div : [optional] divisions, 1 = whole note, 4 = quarter note, ...
local function bpm_to_sec(bpm, div)
  div = div or 1
  return 60.0 / bpm / div
end

local function is_note(event)
  local t = event.type
  return (t == types.NOTE_ON) or (t == types.NOTE_OFF)
end

local function is_clock(event)
  return event.type == types.CLOCK
end

local function is_transport(event)
  local t = event.type
  return ((t == types.START)
      or (t == types.STOP)
      or (t == types.CONTINUE))
end


--
-- objects
--


--
-- Input class (event source)
--
local Input = {}
Input.__index = Input

function Input.new(o)
  local o = setmetatable(o or {}, Input)

  -- determine which device to use
  if not o.device then
    if o.name then
      -- attempt to find the midi device by name
      for i,v in ipairs(midi.vports) do
        if starts_with(v.name, o.name) then
          o.device = midi.connect(i)
        end
      end
    else
      o.device = midi.connect(1)
    end
  end

  -- set defaults
  --o.device = o.device or midi.connect(1)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  -- install device event handler
  o.device.event = function(data)
    o:on_midi_event(data)
  end

  return o
end

function Input:on_midi_event(data)
  if not self.enabled or self.chain == nil then
    -- nothing to do
    return
  end

  local event = midi.to_msg(data)
  if event ~= nil then
    self.chain:process(event)
  end
end


-- allow this input to invoke callbacks
function Input:enable()
  self.enabled = true
end

-- temporarily stop this input from invoking callbacks
function Input:disable()
  self.enabled = false
end

-- perminantly remove this input from receiving further events
function Input:cleanup()
  self:disable()
  if self.device then
    self.device:cleanup()
  end
end

--
-- Output class (event sink)
--
local Output = {}
Output.__index = Output

function Output.new(o)
  local o = setmetatable(o or {}, Output)

  -- defaults
  o.device = o.device or midi.connect(2)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  return o
end

function Output:process(event, output)
  local t = event.type
  if self.enabled and (t ~= nil) then
    -- filter out non-midi events
    if type_names[t] ~= nil then
      self.device:send(event)
    end
  end

  -- pass events on
  output(event)
end


--
-- Clock class (event source)
--
local Clock = {}
Clock.__index = Clock

function Clock.new(o)
  local o = setmetatable(o or {}, Clock)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  o.ch = o.ch or 0

  if o.metro == nil then
    o.metro = metro.init()
  end

  -- setup metro timing and callback
  o.stage = o.stage or 1
  o.interval = o.interval or 1
  o.metro.event = function(stage)
    o.stage = stage
    o:fire(stage)
  end

  return o
end

function Clock:enable()
  self.enabled = true
end

function Clock:disable()
  self.enabled = false
end

function Clock:start()
  -- FIXME: why is the first stage always 1 if the init_stage value is 0?
  self.metro:start(self.interval, -1, self.stage)
  self.chain:process(mk_start(self.ch))
end

function Clock:reset()
  -- TODO: implement this, reset stage to 0 yet retain the same tempo?
  -- or immediately reset?
  self.stage = 0
end

function Clock:stop()
  self.metro:stop()
  self.chain:process(mk_stop(self.ch))
end

function Clock:fire(stage)
  if self.enabled then
    self.chain:process(mk_clock(stage, self.ch))
  end
end

function Clock:cleanup()
  -- ?? metros do need deallocation?
  self.metro.stop()
end


--
-- Chain class
--
local Chain = {}
Chain.__index = Chain

function Chain.new(devices)
  local o = setmetatable({}, Chain)
  o.bypass = false
  o.devices = devices or {}

  -- rip through devices and if there are functions wrap them in a
  -- generic processor object which supports bypass etc.
  for i, d in ipairs(o.devices) do
    if type(d) == 'function' then
      o.devices[i] = Func.new(d)
    end
  end

  o._state = {}
  o._buffers = { Deque.new(), Deque.new() }
  return o
end

function Chain:process(event)
  if self.bypass then
    return
  end

  local state = self._state
  local source = self._buffers[1]
  local sink = self._buffers[2]

  source:clear()
  sink:clear()

  local output = function(event)
    sink:push_back(event)
  end

  -- populate the source event queue with the event to process
  source:push_back(event)

  for i, processor in ipairs(self.devices) do
    event = source:pop()
    while event do
      -- print("\ndevice:", i, "event:", event, "processor:", processor)
      processor:process(event, output, state)
      event = source:pop()
      -- print("sink c:", sink:count())
    end

    -- swap input/output buffers
    local t = source
    source = sink
    sink = t

    -- event = source:pop()
    if source:count() == 0 then
      -- no more events to process, end chain processing early
      -- print("breaking out of process loop")
      break
    end
  end

  -- return output buffer of last processor
  return source
end

function Chain:run(events)
  local output = Deque.new()
  for i, ein in ipairs(events) do
    local r = self:process(ein)
    if r ~= nil then
      -- flatten output
      output:extend_back(r)
    end
  end
  return output:to_array()
end


--
-- Switcher class
--
local Switcher = {}
Switcher.__index = Switcher

function Switcher.new(o)
  local o = setmetatable(o or {}, Switcher)

  -- defaults
  o.which = o.which or 1
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  return o
end

function Switcher:process(event, output)
  local chain = self[self.which]
  if chain ~= nil then
    chain:process(event, output)
  end
end


--
-- Func class
--
local Func = {}
Func.__index = Func

function Func.new(f)
  local o = setmetatable({}, Func)
  o.f = f
  o.bypass = false
  return o
end

function Func:process(event, output, state)
  if self.bypass then
    output(event)
  else
    self.f(event, output, state)
  end
end


--
-- ClockDiv class
--
local ClockDiv = {}
ClockDiv.__index = ClockDiv

function ClockDiv.new(o)
  local o = setmetatable(o or {}, ClockDiv)
  o.div = o.div or 1
  -- TODO: allow targeting of a single channel
  -- TODO: follow START, STOP, RESET events to (re)sync div
  -- TODO: catch assignment to "div" and reset sync? (need to move div
  --       into a props table in order to take advantage of __newindex

  -- TODO: external midi clock sync
  return o
end

function ClockDiv:process(event, output)
  if event.type == types.CLOCK then
    if (event.stage % self.div) == 0 then
      output(event)
    end
  else
    output(event)
  end
end


--
-- Held(note) class
--
local Held = {}
Held.__index = Held
Held.EVENT = Held

function Held.new(o)
  local o = setmetatable(o or {}, Held)
  o._tracking = {}
  o._ordering = Deque.new()
  o.debug = o.debug or false
  return o
end

function Held:mk_event(notes)
  return { type = Held.EVENT, notes = notes }
end

function Held:process(event, output)
  local changed = false
  local t = event.type

  -- TODO: implement "hold" mode

  if t == types.NOTE_ON then
    local k = to_id(event.ch, event.note)
    local e = self._tracking[k]
    if e == nil then
      -- new note on
      self._tracking[k] = {
	count = 1,
	event = event,
      }
      self._ordering:push_back(k)
      changed = true
    else
      -- already tracking, increment count, silent change
      e.count = e.count + 1
    end
  elseif t == types.NOTE_OFF then
    local k = to_id(event.ch, event.note)
    local e = self._tracking[k]
    if e ~= nil then
      if e.count == 1 then
	-- last note lifted
	self._tracking[k] = nil
	self._ordering:remove(k)
	changed = true
      else
	-- decrement count
	e.count = e.count - 1
      end
    end
  else
    -- pass unprocessed events
    output(event)
  end

  if changed then
    local held = {}
    for i, k in self._ordering:ipairs() do
      local e = self._tracking[k]
      -- print(i, k, e)
      held[i] = e.event
    end

    -- debug
    if self.debug then
      print("HELD >>")
      for i, e in ipairs(held) do
	print(i, to_string(e))
      end
      print("<<")
    end

    output(self:mk_event(held))
  end
end


--
-- Pattern class
--
local Pattern = {}
Pattern.__index = Pattern
Pattern.EVENT = Pattern
Pattern.builder = {}

function Pattern.new(o)
  local o = setmetatable(o or {}, Pattern)
  o.style = o.syle or 'up'
  o.debug = o.debug or false

  return o
end

function Pattern:mk_event(value)
  return { type = Pattern.EVENT, value = value }
end

function Pattern:process(event, output, state)
  if event.type == Held.EVENT then
    local builder = self.builder[self.style]
    if builder ~= nil then
      local pattern = builder(event.notes)
      output(self:mk_event(pattern))
      if self.debug then
	print("PAT >>>")
	for i, e in ipairs(pattern) do
	  print(i, to_string(e))
	end
	print("<<< PAT")
      end
    end
  else
    output(event)
  end
end

function Pattern.builder.up(notes)
  local cmp = function(a, b)
    return a.note < b.note
  end
  -- MAINT: in-place sort so note order is lost
  table.sort(notes, cmp)
  return notes
end

function Pattern.builder.down(notes)
  local cmp = function(a, b)
    return a.note > b.note
  end
  table.sort(notes, cmp)
  return notes
end

function Pattern.builder.up_down(notes)
end

function Pattern.builder.up_and_down(notes)
end

function Pattern.builder.converge(notes)
end

function Pattern.builder.diverge(notes)
end

function Pattern.builder.as_played(notes)
  return notes
end

function Pattern.builder.random(notes)
end


--
-- Arp class
--
local Arp = {}
Arp.__index = Arp

function Arp.new(o)
  local o = setmetatable(o or {}, Arp)
  o._pattern = nil
  o._step = 1
  o._length = 0
  o._last = nil
  return o
end

function Arp:set_pattern(notes)
  self._pattern = notes
  self._step = 1
  self._length = #notes
end

function Arp:process(event, output, state)
  if event.type == Pattern.EVENT then
    -- capture and queue up new pattern
    print("arp got pattern change")
    self:set_pattern(event.value)
    return
  end

  if is_clock(event) then
    local last = self._last
    if last ~= nil then
      -- kill previous
      local off = mk_note_off(last.note, last.vel, last.ch)
      output(off)
    end

    if self._pattern ~= nil and self._length > 0 then
      local n = self._step
      local next = self._pattern[n]
      -- print("arp", n, to_string(next))
      output(next)
      self._last = next
      n = n + 1
      if n > self._length then
	self._step = 1
      else
	self._step = n
      end
    end
  end

  if is_note(event) then
    -- don't pass notes
    return
  end

  -- pass everything else
  output(event)
end


--
-- Behavior class
--
local Behavior = {}
Behavior.__index = Behavior

function Behavior.new(o)
  local o = setmetatable(o or {}, Behavior)
  o.bypass = false
  return o
end

function Behavior:process(event, output)
  if self.bypass then
    output(event)
    return
  end

  local t = event.type
  local ch = event.ch

  -- TODO: rebuild this as a table??

  if t == types.NOTE_ON and self.note_on then
    self.note_on(event.note, event.vel, ch)
  elseif t == types.NOTE_OFF and self.note_off then
    self.note_off(event.note, event.vel, ch)
  elseif t == types.PITCH_BEND and self.pitch_bend then
    self.pitch_bend(event.val, ch)
  elseif t == types.CHANNEL_PRESSURE and self.channel_pressure then
    self.channel_pressure(event.val, ch)
  elseif t == types.KEY_PRESSURE and self.key_pressure then
    self.key_pressure(event.val, ch)
  elseif t == types.CONTROL_CHANGE and self.control_change then
    self.control_change(event.cc, event.val, ch)
  elseif t == types.CLOCK and self.clock then
    self.clock()
  elseif t == types.START and self.start then
    self.start()
  elseif t == types.STOP and self.stop then
    self.stop()
  elseif t == types.CONTINUE and self.continue then
    self.continue()
  elseif t == types.PROGRAM_CHANGE and self.program_change then
    self.program_change(event.val, ch)
  end

  output(event)
end


-- Logger class
local Logger = {}
Logger.__index = Logger

function Logger.new(props)
  local o = setmetatable({}, Logger)
  o._props = props
  o.bypass = false
  return o
end

local tu = require 'tabutil'

function Logger:process(event, output)
  if not self.bypass then
    -- TODO: insert call to filter here
    if self._props.filter then
      local r = nil
      self._props.filter:process(event, function(e) r = e end)
      if r ~= nil then
        print(to_string(r))
      end
    else
      print(to_string(event))
    end
  end
  -- always output incoming event
  output(event)
end


-- Thru class
local Thru = {}
Thru.__index = Thru

function Thru.new()
  local o = setmetatable({}, Thru)
  o.bypass = false
  return o
end

function Thru:process(event, output)
  if not self.bypass then
    output(event)
  end
end

-- Filter class
local Filter = {}
Filter.__index = Filter

function Filter.new(o)
  local o = setmetatable(o or {}, Filter)
  o._match = {}
  o.types = o.types or {}
  -- FIXME: __newindex isn't updating table, BROKEN move stuff to props
  o:_build_type_table(o.types)

  if type(o.invert) ~= 'boolean' then
    o.invert = false
  end
  o.bypass = false
  return o
end

function Filter:__newindex(idx, val)
  if idx == "types" then
    -- build event class filter
    self:_build_type_table(val)
    rawset(self, idx, val)
  else
    rawset(self, idx, val)
  end
end

function Filter:_build_type_table(val)
  local t = {}
  -- FIXME: this is a goofy way to do set membership
  for _, v in ipairs(val) do
    t[v] = true
  end
  self._match.types = t
end

function Filter:process(event, output)
  if self.bypass then
    output(event)
    return
  end

  -- TODO: expand on this
  local type_match = self._match.types[event.type]
  if type_match and self.invert then
    output(event)
  end
end


--
-- module
--

return {
  -- objects
  Input = Input.new,
  Output = Output.new,
  Behavior = Behavior.new,
  Chain = Chain.new,
  Switcher = Switcher.new,
  Logger = Logger.new,
  Thru = Thru.new,
  Clock = Clock.new,
  ClockDiv = ClockDiv.new,
  Held = Held.new,
  Filter = Filter.new,
  Func = Func.new,
  Arp = Arp.new,
  Pattern = Pattern.new,

  -- event creators
  mk_note_on = mk_note_on,
  mk_note_off = mk_note_off,
  mk_channel_pressure = mk_channel_pressure,
  mk_key_pressure = mk_key_pressure,
  mk_pitch_bend = mk_pitch_bend,
  mk_control_change = mk_control_change,
  mk_program_change = mk_program_change,
  mk_clock = mk_clock,
  mk_start = mk_start,
  mk_stop = mk_stop,
  mk_continue = mk_continue,

  -- helpers
  to_hz = to_hz,
  to_id = to_id,
  to_bend_range = to_bend_range,
  to_string = to_string,
  bpm_to_sec = bpm_to_sec,

  -- data
  types = types,

  -- debug
  __input_count = input_count,
  __inputs = inputs,
}
