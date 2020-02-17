local table = require('table')

--
-- Held(note) class
--
local Held = {}
Held.__index = Held
Held.EVENT = Held

function Held.new(o)
  local o = setmetatable(o or {}, Held)
  o._tracking = {}
  o._ordering = Deque.new()
  o.debug = o.debug or false
  return o
end

function Held:mk_event(notes)
  return { type = Held.EVENT, notes = notes }
end

function Held:process(event, output)
  local changed = false
  local t = event.type

  -- TODO: implement "hold" mode

  if t == types.NOTE_ON then
    local k = sky.to_id(event.ch, event.note)
    local e = self._tracking[k]
    if e == nil then
      -- new note on
      self._tracking[k] = {
	count = 1,
	event = event,
      }
      self._ordering:push_back(k)
      changed = true
    else
      -- already tracking, increment count, silent change
      e.count = e.count + 1
    end
  elseif t == sky.types.NOTE_OFF then
    local k = sky.to_id(event.ch, event.note)
    local e = self._tracking[k]
    if e ~= nil then
      if e.count == 1 then
	-- last note lifted
	self._tracking[k] = nil
	self._ordering:remove(k)
	changed = true
      else
	-- decrement count
	e.count = e.count - 1
      end
    end
  else
    -- pass unprocessed events
    output(event)
  end

  if changed then
    local held = {}
    for i, k in self._ordering:ipairs() do
      local e = self._tracking[k]
      -- print(i, k, e)
      held[i] = e.event
    end

    -- debug
    if self.debug then
      print("HELD >>")
      for i, e in ipairs(held) do
	      print(i, sky.to_string(e))
      end
      print("<<")
    end

    output(self:mk_event(held))
  end
end


--
-- Pattern class
--
local Pattern = {}
Pattern.__index = Pattern
Pattern.EVENT = Pattern
Pattern.builder = {}

function Pattern.new(o)
  local o = setmetatable(o or {}, Pattern)
  o.style = o.syle or 'up'
  o.debug = o.debug or false

  return o
end

function Pattern:mk_event(value)
  return { type = Pattern.EVENT, value = value }
end

function Pattern:process(event, output, state)
  if event.type == Held.EVENT then
    local builder = self.builder[self.style]
    if builder ~= nil then
      local pattern = builder(event.notes)
      output(self:mk_event(pattern))
      if self.debug then
        print("PAT >>>")
        for i, e in ipairs(pattern) do
          print(i, sky.to_string(e))
        end
        print("<<< PAT")
      end
    end
  else
    output(event)
  end
end

function Pattern.builder.up(notes)
  local cmp = function(a, b)
    return a.note < b.note
  end
  -- MAINT: in-place sort so note order is lost
  table.sort(notes, cmp)
  return notes
end

function Pattern.builder.down(notes)
  local cmp = function(a, b)
    return a.note > b.note
  end
  table.sort(notes, cmp)
  return notes
end

function Pattern.builder.up_down(notes)
end

function Pattern.builder.up_and_down(notes)
end

function Pattern.builder.converge(notes)
end

function Pattern.builder.diverge(notes)
end

function Pattern.builder.as_played(notes)
  return notes
end

function Pattern.builder.random(notes)
end


--
-- Arp class
--
local Arp = {}
Arp.__index = Arp

function Arp.new(o)
  local o = setmetatable(o or {}, Arp)
  o._pattern = nil
  o._step = 1
  o._length = 0
  o._last = nil
  return o
end

function Arp:set_pattern(notes)
  self._pattern = notes
  self._step = 1
  self._length = #notes
end

function Arp:process(event, output, state)
  if event.type == Pattern.EVENT then
    -- capture and queue up new pattern
    print("arp got pattern change")
    self:set_pattern(event.value)
    return
  end

  if is_clock(event) then
    local last = self._last
    if last ~= nil then
      -- kill previous
      local off = sky.mk_note_off(last.note, last.vel, last.ch)
      output(off)
    end

    if self._pattern ~= nil and self._length > 0 then
      local n = self._step
      local next = self._pattern[n]
      -- print("arp", n, to_string(next))
      output(next)
      self._last = next
      n = n + 1
      if n > self._length then
	self._step = 1
      else
	self._step = n
      end
    end
  end

  if is_note(event) then
    -- don't pass notes
    return
  end

  -- pass everything else
  output(event)
end

--
-- module
--

return {
  Held = Held.new,
  Pattern = Pattern.new,
  Arp = Arp.new,
}