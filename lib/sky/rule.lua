--
-- a collection of abstractions for making selections from a population
--

local table = require('table')
local music = require('musicutil')

local choice = include('meso/lib/sky/choice')

--
-- Rule object
--
local Rule = {}
Rule.__index = Rule

--- constructor
-- @param items : values selected by rule
-- @param weights : non-normalized list of numbers to use as weights, extends
function Rule.new(items, weights, name)
  local o = setmetatable({}, Rule)
  o._name = name or ''
  o._items = items
  local w, c = {}, choice.cycle(weights)
  for _, i in ipairs(items) do
    table.insert(w, c())
  end
  o._selector = choice.Choice.new(w)
  return o
end

function Rule:name()
  return self._name
end

function Rule:items()
  return self._items
end

function Rule:weights()
  return self._selector:values()
end

function Rule:__call()
  return self._items[self._selector()]
end

function Rule:__tostring()
  return '<Rule: "' .. self._name .. '", items: ' .. tostring(self._items) ..
    ', selector: ' .. tostring(self._selector) .. '>'
end

--
-- helpers
--

local SEMITONE_INTERVAL_NAMES = {
  "P1", "m2", "M2", "m3", "M3", "P4", "b5", "P5", "m6", "M6", "m7", "M7", "P8",
  "m9", "M9", "m10", "M10", "P11", "m125", "P15", "m14", "M14", "m15",  "M15",
}

local function semitone_scale_rule(scale_name, weights)
  for _, scale in ipairs(music.SCALES) do
    if scale.name == scale_name then
      return Rule.new(scale.intervals, weights, scale_name)
    end
  end
end


local DURATION_NAMES = {'1', '1/2.', '1/2', '1/4.', '1/4', '1/8.', '1/8', 'Triplet', '1/16'}
local DURATION_DEMISEMIQUAVERS = {32, 24, 16, 12, 8, 6, 4, 3, 2}

local function demisemiquaver_rhythm_rule(weights)
  return Rule.new(DURATION_DEMISEMIQUAVERS, weights)
end

--
-- exports
--
return {
  Rule = Rule,

  semitone_scale_rule = semitone_scale_rule,
  demisemiquaver_rhythm_rule = demisemiquaver_rhythm_rule,

  DURATION_NAMES = DURATION_NAMES,
  DURATION_DEMISEMIQUAVERS = DURATION_DEMISEMIQUAVERS,
}