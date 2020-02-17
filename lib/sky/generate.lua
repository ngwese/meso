-- local choice = include('meso/lib/sky/choice')
local rule = include('meso/lib/sky/rule')

local DEFAULT_SCALE_RULE = rule.semitone_scale_rule("Major", {100})
local DEFAULT_RHYTHM_RULE = rule.demisemiquaver_rhythm_rule({100, 20})

--
-- Note
--

local Note = {}
Note.__index = Note

function Note.new(o)
  local o = setmetatable(o, Note)
  return o
end

function Note:__tostring()
  return '<Note semitone offset: ' .. self.semitone .. ', duration: ' .. self.duration .. '>'
end

--
-- Generator
--

local Generator = {}
Generator.__index = Generator

function Generator.new(o)
  local o = setmetatable(o or {}, Generator)
  if not o.scale_rule then
    o.scale_rule = DEFAULT_SCALE_RULE
  end
  if not o.rhythm_rule then
    o.rhythm_rule = DEFAULT_RHYTHM_RULE
  end
  return o
end

function Generator:__call()
  return Note.new{
    semitone = self:scale_rule(),
    duration = self:rhythm_rule(),
  }
end

--
-- exports
--
return {
  DEFAULT_SCALE_RULE = DEFAULT_SCALE_RULE,
  DEFAULT_RHYTHM_RULE = DEFAULT_RHYTHM_RULE,

  Generator = Generator,
  Note = Note,
}