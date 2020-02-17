--
-- a collection of abstractions for making selections from a population
--

local math = require('math')
local table = require('table')

--- infinitely cycle through values in list
-- @param values : a list of things
-- @return a function
local function cycle(values)
  local i, size = 1, #values
  return function()
    local next = values[i]
    i = i + 1
    if i > size then i = 1 end
    return next
  end
end

--- nornalize array as a set of weights which sum to 1.0
-- @param values : an list of numbers
-- @return list of numbers
local function as_weights(values)
  local weights, sum = {}, 0
  for _, v in ipairs(values) do
    sum = sum + v
  end
  for _, v in ipairs(values) do
    table.insert(weights, v/sum)
  end
  return weights
end

--- generator of indexes between [1, #weights] with the given distribution
-- @param weights : a list of weights which sum to 1.0
-- @return a function
local function build_weighted_selector(weights)
  local partial_sums, sum = {}, 0
  for _, weight in ipairs(weights) do
    sum = sum + weight
    table.insert(partial_sums, sum)
  end
  local max_i = #partial_sums
  return function()
    local r, sum = math.random(), 0
    for i, sum_i in ipairs(partial_sums) do
      sum = sum + sum_i
      if sum_i > r then
        return i
      end
    end
    return max_i
  end
end

--
-- Choice object
--
local Choice = {}
Choice.__index = Choice

--- constructor
-- @param weights : non-normalized list of numbers to use as weights
function Choice.new(values)
  local o = setmetatable({}, Choice)

  o._values = values
  o._weights = as_weights(values)
  o._gen = build_weighted_selector(o._weights)
  o._max = #o._weights

  return o
end

function Choice.even()
  return Choice.new({1.0})
end

function Choice:values()
  return self._values
end

function Choice:__call()
  return self._gen()
end

function Choice:next_in(max)
  -- FIXME: this do not really retain the distribution and assumes that max >= self:max
  local sm = self:max()
  local num_wrap = max // sm
  local num_rem = max % sm
  if num_rem ~= 0 then
    num_wrap = num_wrap + 1
  end
  local which_wrap = math.random(num_wrap)
  local n = self:next()
  local c = (which_wrap * sm) + n
  if c > max then
    return math.random(((num_wrap - 1) * sm) + n)
  end
  return c
end

function Choice:max()
  return self._max
end

function Choice:range()
  return 1, self:max()
end

-- function Choice:__tostring()
--   return '<Choice>'
-- end

--
-- exports
--
return {
  cycle = cycle,
  as_weights = as_weights,
  build_weighted_selector = build_weighted_selector,
  Choice = Choice,
}