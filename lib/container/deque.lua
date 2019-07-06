-- deque - double ended queue
-- @module deque
-- @alias Deque

-- reference: https://www.lua.org/pil/11.4.html


local REMOVED = { 'deque removed value' }

local Deque = {}
Deque.__index = Deque

function Deque.new(elements)
  local o = setmetatable({}, Deque)
  o.first = 0
  o.last = -1
  o.tombstones = 0
  if elements ~= nil then
    for _, e in ipairs(elements) do
      o:push_back(e)
    end
  end
  return o
end

function Deque:push(value)
  local first = self.first - 1
  self.first = first
  self[first] = value
end

function Deque:push_back(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function Deque:extend_back(other_deque)
  for _, e in other_deque:ipairs() do
    self:push_back(e)
  end
end

function Deque:pop()
  local first = self.first
  if first > self.last then
    -- empty
    return nil
  end
  local value = self[first]
  self[first] = nil
  self.first = first + 1
  if value ~= REMOVED then
    return value
  end
  -- tail call to skip over tombstone
  self.tombstones = self.tombstones - 1
  return self:pop()
end

function Deque:pop_back()
  local last = self.last
  if self.first > last then
    -- empty
    return nil
  end
  local value = self[last]
  self[last] = nil
  self.last = last - 1
  if value ~= REMOVED then
    return value
  end
  -- tail call to skip over tombstone
  self.tombstones = self.tombstones - 1
  return self:pop_back()
end

function Deque:remove(value, predicate)
  if predicate == nil then
    predicate = function(a, b)
      return a == b
    end
  end

  -- optimal case (match head or tail)
  if predicate(self[self.first], value) then
    return self:pop()
  elseif predicate(self[self.last], value) then
    return self:pop_back()
  end

  -- search for a match and tombstone it
  for i, v in ipairs(self) do
    if predicate(v, value) then
      self[i] = REMOVED
      self.tombstones = self.tombstones + 1
      return v
    end
  end

  return nil
end

function Deque:count()
  if self.last < self.first then
    return 0
  end
  return self.last - self.first - self.tombstones + 1
end

function Deque:clear()
  for k, _ in pairs(self) do
    self[k] = nil
  end
  -- must match new()
  self.first = 0
  self.last = -1
  self.tombstones = 0
end

function Deque:ipairs()
  local first = self.first
  local last = self.last
  local i = first
  local n = 0
  local f

  f = function()
    if i > last then
      return nil
    end
    local element = self[i]
    i = i + 1
    if element ~= REMOVED then
      n = n + 1
      return n, element
    end
    -- tail call to skip tombbstone
    return f()
  end

  return f
end

function Deque:to_array()
  local r = {}
  for i, e in self:ipairs() do
    r[i] = e
  end
  return r
end

return Deque




