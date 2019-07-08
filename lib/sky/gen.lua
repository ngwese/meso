--
-- objects to generate musical events
--

--
-- Voice (base)
--

local Voice = {}
Voice.__index = Voice

function Voice.new(o)
  local o = setmetatable(o or {}, Voice)
  -- defaults
  o.name = o.name or "?"
  o.pitch = o.pitch or 64 -- TODO: something other than midi note number?
  o.mute = o.mute or false
  o.length = o.length or 3
  o.length_range = o.length_range or 9
  o.gaps = o.gaps or 3
  o.gaps_range = o.gaps_range or 9
  o.note_rest = o.note_rest or 0
  return o
end

function Voice:_type_name()
  return 'Voice'
end

function Voice:__tostring()
  local s = '<' .. self:_type_name()
  for k, v in pairs(self) do
    if v ~= self then
      s = s .. ' ' .. tostring(k) .. '=' .. tostring(v)
    end
  end
  return s .. '>'
end

--
-- RythmicVoice
--

local RythmicVoice = {}
RythmicVoice.__index = RythmicVoice
setmetatable(RythmicVoice, Voice)

function RythmicVoice.new(o)
  local o = Voice.new(o)
  setmetatable(o, RythmicVoice)
  return o
end

function RythmicVoice:_type_name()
  return 'RythmicVoice'
end

--
-- FollowVoice
--

local FollowVoice = {}
FollowVoice.__index = FollowVoice
setmetatable(FollowVoice, Voice)

function FollowVoice.new(o)
  local o = Voice.new(o)
  setmetatable(o, FollowVoice)
  -- defaults
  o.percent = o.percent or 60
  o.strategy = o.strategy or 'chordal'
  return o
end

function FollowVoice:_type_name()
  return 'FollowVoice'
end

-- TODO: AmbientVoice, RepeatVoice, PatternVoice

--
-- Articulation (voice parameter)
--

local Articulation = {}
Articulation.__index = Articulation

function Articulation.new(o)
  local o = setmetatable(o or {}, Articulation)
  o.minimum = o.minimum or 100
  o.range = o.range or 20
  o.variation = o.variation or 0 -- '?'
  o.variation_range = o.variation_range or 0 -- '?'
  return o
end

function Articulation:_type_name()
  return 'Articulation'
end

function Articulation:__tostring()
  return '<' .. self:_type_name() .. '>'
end

--
-- Chords (voice parameter)
--




--
-- Rule(s)
--

local RULE_INTERVAL_NAMES = {
  "P1", "m2", "M2", "m3", "M3", "P4", "b5", "P5", "m6", "M6", "m7", "M7", "P8",
  "m9", "M9", "m10", "M10", "P11", "m125", "P15", "m14", "M14", "m15",  "M15",
}

local RULE_DURATION_NAMES = {
  "1", "1/2.", "1/2", "1/4.", "1/4", "1/8.", "1/8", "Triplet", "1/16",
}

local Rule = {}
Rule.__index = Rule

function Rule.new(o)
  local o = setmetatable(o or {}, Rule)
  return o
end

function Rule:_type_name()
  return 'Rule'
end

function Rule:__tostring()
  return '<' .. self:_type_name() .. '>'
end


local ScaleRule = {}
ScaleRule.__index = ScaleRule
setmetatable(ScaleRule, Rule)

function ScaleRule.new(o)
  local o = setmetatable(o or {}, ScaleRule)
  o._size = #o
  return o
end

function ScaleRule:_type_name()
  return 'ScaleRule'
end


--
-- module
--

return {
  RythmicVoice = RythmicVoice.new,
  FollowVoice = FollowVoice.new,
  ScaleRule = ScaleRule.new,
}
