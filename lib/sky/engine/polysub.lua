--
-- PolySub (glue)
--

-- mutate global used by matron to select engine
engine.name = "PolySub"

local glue = include('we/lib/polysub')

local Singleton = nil

local PolySub = {}
PolySub.__index = PolySub

function PolySub.new(props)
  local o = setmetatable(props, PolySub)
  -- MAINT: params aren't owned so it is hard to remove
  glue.params()
  o.next_voice = 1
  o.voices = {}
  return o
end

function PolySub:process(event, output, state)
  if event.type == sky.types.NOTE_ON then
    local existing = self.voices[event.note]
    if existing then
      engine.stop(existing)
    end
    engine.start(self.next_voice, sky.to_hz(event.note))
    self.voices[event.note] = self.next_voice
    self.next_voice = self.next_voice + 1
  elseif event.type == sky.types.NOTE_OFF then
    local existing = self.voices[event.note]
    if existing then
      engine.stop(existing)
    end
    self.voices[event.note] = nil
  end
  output(event)
end

local function shared_instance(props)
  if Singleton == nil then
    Singleton = PolySub.new(props)
  end
  return Singleton
end

return {
  PolySub = shared_instance,
}