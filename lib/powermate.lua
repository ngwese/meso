--
-- powermate adaptor
--

--local hid = require 'hid'

local Powermate = {}
Powermate.__index = Powermate

Powermate.connect = function(num)
  local o = setmetatable({}, Powermate)

  -- no-op handlers
  o.enc = function(num, delta)
  end
  
  o.key = function(num, z)
  end
  
  -- connect up device
  o.device = hid.connect(num)
  o.device.event = function(type, code, value)
    if type == 2 and code == 7 then
      o.enc(1, value)
    elseif type == 1 and code == 256 then
      o.key(1, value)
    end
  end

  return o
end

return Powermate

  