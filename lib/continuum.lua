--
-- continuum fingerboard helpers
--

local util = require "util"
local ControlSpec = require "controlspec"

local abs_ch = 15
local cfg_ch = 16

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

--
-- performance controller assignments (section 14)
--
function Continuum:octave_shift(direction)
  local center = 60
  local shift = clamp(center + (direction * 12))
  self.device:cc(8, shift, abs_ch)
end

function Continuum:mono_switch(value)
  -- TODO
end

function Continuum:fine_tune(cents)
  local tune = util.clamp(64 + cents, 0, 127)
  self.device:cc(10, tune, abs_ch)
end

local barrel_to_cc = {12, 13, 14, 15}

function Continuum:barrel(which, value)
  if which > 0 and which <= 4 then
    self.device:cc(barrel_to_cc[which], clamp(value), abs_ch)
  end
end

local gen_to_cc = {16, 17}

function Continuum:gen(which, value)
  if which > 0 and which <= 2 then
    self.device:cc(gen_to_cc[which], clamp(value), abs_ch)
  end
end

function Continuum:gain(value)
  self.device:cc(18, clamp(value), abs_ch)
end

function Continuum:input_level(value)
  self.device:cc(19, clamp(value), abs_ch)
end

local r_to_cc = {20, 21, 22, 23}

function Continuum:r(which, value)
  if which > 0 and which <= 4 then
    -- FIXME: verify this value handling, the docs mention an offset
    self.device:cc(r_to_cc[which], clamp(value), abs_ch)
  end
end

function Continuum:recirculator_mix(value)
  self.device:cc(24, clamp(value), abs_ch)
end

function Continuum:round_rate(value)
  self.device:cc(25, clamp(value), abs_ch)
end

-- constants for use with `round_initial` method
Continuum.ROUND_INITIAL_NONE = 0      -- FIXME: verify
Continuum.ROUND_INITIAL_TUNING = 127  -- FIXME: verify

function Continuum:round_initial(value)
  self.device:cc(28, value, abs_ch)
end

-- constants for use with `advance` method
Continuum.ADVANCE_FULL = 127
Continuum.ADVANCE_HALF = 64

function Continuum:advance(mode)
  self.device:cc(31, mode, abs_ch)
end

-- constants for use with `equal` method
Continuum.ROUND_IGNORE = 0
Continuum.ROUND_PRESET = 64
Continuum.ROUND_EQUAL = 127

function Continuum:equal(mode)
  self.device:cc(65, mode, abs_ch)
end

function Continuum:sustain(value)
  self.device:cc(65, clamp(value), abs_ch)
end

function Continuum:sostenuto(which, value)
  if which == 1 then
    self.device:cc(66, clamp(value), abs_ch)
  elseif which == 2 then
    self.device:cc(69, clamp(value), abs_ch)
  end
end

--
-- configuration controller assignments (section 15)
--

--
-- 15.1 load, store, and list presets
--

function Continuum:load_preset(num)
  if num > 0 and num <= 512 then
    lsb = 0x7f & num
    msb = 0x7f & (num >> 7)
    print("lsb", lsb, "msb", msb)
    self.device:cc(80, lsb, cfg_ch)
    self.device:cc(81, msb, cfg_ch)
  end
end

function Continuum:transmit_config()
  self.device:cc(109, 0, cfg_ch) -- FIXME: verify
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

--
-- 15.5 polyphony, routing, and split
--

--
-- 15.6 pedal jack configuration
--

function Continuum:jack_cc(which, cc_num)
  if which == 1 then
    self.device:cc(52, clamp(cc_num), cfg_ch)
  elseif which == 2 then
    self.device:cc(53, clamp(cc_num), cfg_ch)
  end
end 

function Continuum:jack_range(which, min, max)
  if which == 1 then
    self.device:cc(76, clamp(min), cfg_ch)
    self.device:cc(77, clamp(max), cfg_ch)
  elseif which == 2 then
    self.device:cc(78, clamp(min), cfg_ch)
    self.device:cc(79, clamp(max), cfg_ch)
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
  self.device:cc(46, util.clamp(mode, 0, 5), cfg_ch)
end

function Continuum:mono_interval(interval)
  self.device:cc(48, util.clamp(interval, 0, 96), cfg_ch)
end

--
-- 15.8 firmware version and cvc serial number
--

function Continuum:_get_firmware_version()
  -- ??? not sure how to interpret the instructions, does the device send midi back in response?
  self.device:cc(102, 0, cfg_ch)
  self.device:cc(103, 0, cfg_ch)
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
  -- self.device:cc(110, num, cfg_ch)
  -- self.device:cc(115, 1, cfg_ch)

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
