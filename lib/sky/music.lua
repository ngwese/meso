--
-- objects to represent musical quantities
--

local Metre = {}
Metre.__index = Metre

function Metre.new(beats, length)
  local o = setmetatable({}, Metre)
  o[1] = beats or 4
  o[2] = length or 4
  return o
end

function Metre:__tostring()
  local a = self[1]
  if a ~= nil then
    a = tostring(a)
  else
    a = '?'
  end
  local b = self[2]
  if b ~= nil then
    b = tostring(b)
  else
    b = '?'
  end
  return a .. '/' .. b
end

--
-- module
--

return {
  Metre = Metre.new
}
