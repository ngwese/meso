--
-- continuum finger board helpers
--

local util = require "util"

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


return Continuum