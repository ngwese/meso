--
-- Filter
--

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

return {
  Filter = Filter.new,
}

