--
-- powermate adaptor
--

--local hid = require 'hid'

local Powermate = {}
Powermate.__index = Powermate
Powermate.MAGIC_SPEED_SHIFT = 8
Powermate.MAGIC_PULSE_SHIFT = 17
Powermate.MAGIC_ASLEEP_SHIFT = 19
Powermate.MAGIC_AWAKE_SHIFT = 20

function Powermate.connect(num)
  local self = setmetatable({}, Powermate)

  -- no-op handlers
  self.enc = function(num, delta)
  end
  
  self.key = function(num, z)
  end
  
  -- connect up device
  self.device = hid.connect(num)
  self.device.event = function(type, code, value)
    if type == 2 and code == 7 then
      self.enc(1, value)
    elseif type == 1 and code == 256 then
      self.key(1, value)
    end
  end

  return self
end

function Powermate:_set_cfg(brightness, pulse_speed, asleep, awake, pulse_table)
  pulse_table = pulse_table or 0
  
  if asleep or false then asleep = 1 else asleep = 0  end
  if awake or false then awake = 1 else awake = 0 end
  
  local value = (
    brightness  |
    pulse_speed << self.MAGIC_SPEED_SHIFT  |
    pulse_table << self.MAGIC_PULSE_SHIFT  |
    asleep      << self.MAGIC_ASLEEP_SHIFT |
    awake       << self.MAGIC_AWAKE_SHIFT
  )
  
  print(value)
  local etype = self.device.device.types.EV_MSC   -- yuck
  local code = self.device.device.codes.MSC_PULSELED
  return self.device.device:send(etype, code, value)
end

function Powermate:set_steady_led(brightness)
  self:_set_cfg(brightness, 0, false, false)
end

function Powermate:set_pulse(speed)
  -- pulse speed (0-510)
  self:_set_cfg(0, speed, false, false)
end

return Powermate

  