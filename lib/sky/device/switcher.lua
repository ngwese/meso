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

return {
  Switcher = Switcher.new,
}