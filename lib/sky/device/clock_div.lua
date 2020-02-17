--
-- ClockDiv
--

local ClockDiv = {}
ClockDiv.__index = ClockDiv

function ClockDiv.new(o)
  local o = setmetatable(o or {}, ClockDiv)
  o.div = o.div or 1
  -- TODO: allow targeting of a single channel
  -- TODO: follow START, STOP, RESET events to (re)sync div
  -- TODO: catch assignment to "div" and reset sync? (need to move div
  --       into a props table in order to take advantage of __newindex

  -- TODO: external midi clock sync
  return o
end

function ClockDiv:process(event, output)
  if event.type == sky.types.CLOCK then
    if (event.stage % self.div) == 0 then
      output(event)
    end
  else
    output(event)
  end
end

return {
  ClockDiv = ClockDiv.new
}