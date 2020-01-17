--
-- continuum fingerboard helpers
--

local util = require "util"
local ControlSpec = require "controlspec"

local function clamp(value)
  return util.clamp(value, 0, 127)
end

local Continuum = {}
Continuum.__index = Continuum

function Continuum.connect(num)
  local o = setmetatable({}, Continuum)

  -- connect up device
  o.device = midi.connect(num)

  return o
end

-- channel constants 
Continuum.ABS_CH = 1
Continuum.REL_CH = 2
Continuum.CFG_CH = 16

--
-- performance controller assignments (section 14)
--
function Continuum:octave_shift(direction)
  local center = 60
  local shift = clamp(center + (direction * 12))
  self.device:cc(8, shift, self.ABS_CH)
end

function Continuum:mono_switch(value)
  -- TODO
end

function Continuum:fine_tune(cents)
  local tune = util.clamp(64 + cents, 0, 127)
  self.device:cc(10, tune, self.ABS_CH)
end

local barrel_to_cc = {12, 13, 14, 15}

function Continuum:barrel(which, value)
  if which > 0 and which <= 4 then
    self.device:cc(barrel_to_cc[which], clamp(value), self.ABS_CH)
  end
end

local gen_to_cc = {16, 17}

function Continuum:gen(which, value)
  if which > 0 and which <= 2 then
    self.device:cc(gen_to_cc[which], clamp(value), self.ABS_CH)
  end
end

function Continuum:gain(value)
  self.device:cc(18, clamp(value), self.ABS_CH)
end

function Continuum:input_level(value)
  self.device:cc(19, clamp(value), self.ABS_CH)
end

local r_to_cc = {20, 21, 22, 23}

function Continuum:r(which, value)
  if which > 0 and which <= 4 then
    -- FIXME: verify this value handling, the docs mention an offset
    self.device:cc(r_to_cc[which], clamp(value), self.ABS_CH)
  end
end

function Continuum:recirculator_mix(value)
  self.device:cc(24, clamp(value), self.ABS_CH)
end

function Continuum:round_rate(value)
  self.device:cc(25, clamp(value), self.ABS_CH)
end

-- constants for use with `round_initial` method
Continuum.ROUND_INITIAL_NONE = 0      -- FIXME: verify
Continuum.ROUND_INITIAL_TUNING = 127  -- FIXME: verify

function Continuum:round_initial(value)
  self.device:cc(28, value, self.ABS_CH)
end

-- constants for use with `advance` method
Continuum.ADVANCE_FULL = 127
Continuum.ADVANCE_HALF = 64

function Continuum:advance(mode)
  self.device:cc(31, mode, self.ABS_CH)
end

function Continuum:advance_full()
  self:advance(self.ADVANCE_FULL)
end

function Continuum:advance_half()
  self:advance(self.ADVANCE_HALF)
end

-- constants for use with `equal` method
Continuum.ROUND_IGNORE = 0
Continuum.ROUND_PRESET = 64
Continuum.ROUND_EQUAL = 127

function Continuum:equal(mode)
  self.device:cc(65, mode, self.ABS_CH)
end

function Continuum:sustain(value)
  self.device:cc(65, clamp(value), self.ABS_CH)
end

function Continuum:sostenuto(which, value)
  if which == 1 then
    self.device:cc(66, clamp(value), self.ABS_CH)
  elseif which == 2 then
    self.device:cc(69, clamp(value), self.ABS_CH)
  end
end

--
-- configuration controller assignments (section 15)
--

--
-- 15.1 load, store, and list presets
--

function Continuum:load_preset(num) -- broken
  num = util.clamp(num, 1, 511)
  lsb = 0x7f & num
  msb = 0x7f & (num >> 7)
  print("lsb", lsb, "msb", msb)
  self.device:cc(81, lsb, self.CFG_CH)
  self.device:cc(82, msb, self.CFG_CH)
end

function Continuum:load_preset2(category, preset)
  local c = util.clamp(category, 0, 127)
  local p = util.clamp(preset, 1, 127)
  self.device:cc(0, c, self.CFG_CH)
  self.device:cc(32, p, self.CFG_CH)
end

function Continuum:transmit_config()
  self.device:cc(109, 16, self.CFG_CH)
end

function Continuum:transmit_updates(on)
  if on then
    self.device:cc(55, 1, self.CFG_CH)
  else
    self.device:cc(55, 0, self.CFG_CH)
  end
end

--
-- 15.2 midi device compatibility
--

--
-- 15.3 x, y, z coding
--

--
-- 15.4 rounding and pitch tables
--

function Continuum:round_rate_normal()
  self.device:cc(61, 0, self.CFG_CH)
end

function Continuum:round_rate_release()
  self.device:cc(61, 1, self.CFG_CH)
end

--
-- 15.5 polyphony, routing, and split
--

function Continuum:base_polyphony(polyphony, increase_rate, expanded_poly)
  local n = util.clamp(polyphony, 1, 16)
  if increase_rate then
    n = n + 32
  end
  if expanded_ploy then
    n = n + 64
  end
  self.device:cc(39, n, self.CFG_CH)
end

function Continuum:surface_routing(options)
  local n = 0
  for i,option in ipairs(options) do
    if option == "out" then
      n = n | 1 
    elseif option == "internal" then
      n = n | 1 << 1
    elseif option == "cvc" then
      n = n | 1 << 2
    end
  end
  self.device:cc(36, n, self.CFG_CH)
end

function Continuum:midi_input_routing(options)
  local n = 0
  for i,option in ipairs(options) do
    if option == "out" then
      n = n | 1 << 3
    elseif option == "internal" then
      n = n | 1 << 4
    elseif option == "cvc" then
      n = n | 1 << 5
    end
  end
  self.device:cc(36, n, self.CFG_CH)
end

function Continuum:split_point(note)
  self.device:cc(45, clamp(note), self.CFG_CH)
end

function Continuum:split_mode(options)
  -- TODO
end

--
-- 15.6 pedal jack configuration
--

function Continuum:jack_cc(which, cc_num)
  if which == 1 then
    self.device:cc(52, clamp(cc_num), self.CFG_CH)
  elseif which == 2 then
    self.device:cc(53, clamp(cc_num), self.CFG_CH)
  end
end 

function Continuum:jack_range(which, min, max)
  if which == 1 then
    self.device:cc(76, clamp(min), self.CFG_CH)
    self.device:cc(77, clamp(max), self.CFG_CH)
  elseif which == 2 then
    self.device:cc(78, clamp(min), self.CFG_CH)
    self.device:cc(79, clamp(max), self.CFG_CH)
  end
end 

--
-- 15.7 mono function
--

Continuum.MF_PORTAMENTO = 0
Continuum.MF_LEGATO_Z = 1
Continuum.MF_RETRIGGER_Z = 2
Continuum.MF_LEGATO_T = 3
Continuum.MF_RETRIGGER_NEW = 4
Continuum.MF_RETRIGGER_ALL = 5

function Continuum:mono_function(mode)
  self.device:cc(46, util.clamp(mode, 0, 5), self.CFG_CH)
end

function Continuum:mono_interval(interval)
  self.device:cc(48, util.clamp(interval, 0, 96), self.CFG_CH)
end

--
-- 15.8 firmware version and cvc serial number
--

function Continuum:_get_firmware_version()
  -- ??? not sure how to interpret the instructions, does the device send midi back in response?
  self.device:cc(102, 0, self.CFG_CH)
  self.device:cc(103, 0, self.CFG_CH)
end

--
-- 15.9 other configuration controller assignments
--

--
-- custom stuff reverse engineered from the editor
--

function Continuum:query_parameter(num)
  -- the 'Continuum Request Profile.mid' file appears to ping each
  -- of the controls the editor is interested in by sending a cc 110 <param_cc_num> on ch 16
  -- followed by cc 115 1 on ch 16
  -- self.device:cc(110, num, self.CFG_CH)
  -- self.device:cc(115, 1, self.CFG_CH)

  -- start query?
  self.device:cc(110, 127, 16)

  self.device:cc(115, 1, 16)
  self.device:cc(110, num, 16)
  self.device:cc(8, 64, 8)

  -- stop query?
  self.device:cc(110, 0, 16)
end

--
-- parameters
--

local BARREL_NAMES = {"i", "ii", "iii", "iv"}
local ID_PREFIX = "continuum_"

local function repeated_number_param(num, id, name, action)
  return {
    type = "number",
    id = id,
    name = name,
    min = 0,
    max = 127,
    action = function (value)
      action(id, num, value)
    end
  }
end

local function number_param(id, name, action)
  return {
    type = "number",
    id = id,
    name = name,
    min = 0,
    max = 127,
    action = action
  }
end

function Continuum:_build_barrel_param(barrel_num, action)
  local param_id = ID_PREFIX .. "barrel" .. barrel_num
  local name = BARREL_NAMES[barrel_num]
  return repeated_number_param(barrel_num, param_id, name, action)
end

function Continuum:_build_gen_param(gen_num, action)
  local param_id = ID_PREFIX .. "gen" .. gen_num
  local name = "gen" .. gen_num
  return repeated_number_param(gen_num, param_id, name, action)
end

function Continuum:_build_gain_param(action)
  local param_id = ID_PREFIX .. "gain"
  local name = "gain"
  return number_param(param_id, name, action)
end

function Continuum:_build_rec_ctl_param(r_num, action)
  local param_id = ID_PREFIX .. "rec" .. r_num
  local name = "r" .. r_num
  return repeated_number_param(r_num, param_id, name, action)
end

function Continuum:_build_rec_mix_param(action)
  local param_id = ID_PREFIX .. "rec_mix"
  local name = "r mix"
  return number_param(param_id, name, action)
end


function Continuum:add_params()
  -- gain
  params:add(self:_build_gain_param(function (v)
    self:gain(v)
  end))

  -- barrel
  for i = 1, 4 do
    params:add(self:_build_barrel_param(i, function (i, n, v)
      self:barrel(n, v)
    end))
  end

  -- gen
  for i = 1, 2 do
    params:add(self:_build_gen_param(i, function (i, n, v)
      self:gen(n, v)
    end))
  end

  -- recirculator control
  for i = 1, 4 do
    params:add(self:_build_rec_ctl_param(i, function (i, n, v)
      self:r(n, v)
    end))
  end

  -- recirculator mix
  params:add(self:_build_rec_mix_param(function (v)
    self:recirculator_mix(v)
  end))
end

return Continuum
