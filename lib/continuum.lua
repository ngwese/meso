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


  


return Continuum
