--
-- Transpose (midi semitones)
--

local Transpose = {}
Transpose.__index = Transpose

function Transpose.new(o)
  local o = setmetatable(o, Transpose)
  o.bypass = false
  o.semitones = o.semitones or 12
  return o
end

function Transpose:process(event, output)
  if not self.bypass then
    if sky.is_note(event) then
      -- FIXME: need to dup?
      event.note = util.clamp(event.note + self.semitones, 0, 127)
    end
  end
  output(event)
end

return {
  Transpose = Transpose.new,
}