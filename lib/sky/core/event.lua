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
-- helpers
--

--- convert midi note number to frequency in hz
-- @param num : integer midi note number
local function to_hz(num)
  local exp = (num - 21) / 12
  return 27.5 * 2^exp
end


local MIDI_BEND_ZERO = 1 << 13
--- convert midi pitch bend to [-1, 1] range
-- @param value : midi pitch bend value (assumed to be 14 bit)
local function to_bend_range(value)
  local range = MIDI_BEND_ZERO
  if value > MIDI_BEND_ZERO then
    range = range - 1
  end
  return (value - MIDI_BEND_ZERO) / range
end

--- pack midi channel and note values into a numeric value useful as an id or key
-- @param ch : integer channel number
-- @param num : integer note number
local function to_id(ch, num)
  return ch << 8 | num
end

--- convert midi event object to a readable string
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

--- return true if str starts with start (string)
-- @param str : the string to test
-- @param start : the string appearing at the beginning
local function starts_with(str, start)
  return str:sub(1, #start) == start
end

--- convert bpm value to equivalent interval in seconds
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
-- module
--

return {
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
  starts_with = starts_with,
  bpm_to_sec = bpm_to_sec,
  is_note = is_note,
  is_clock = is_clock,
  is_transport = is_transport,

  -- data
  types = types,
  type_names = type_names,
}
