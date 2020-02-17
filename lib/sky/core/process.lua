-- midi helper module
-- @module process
-- @alias process

local Deque = include('meso/lib/container/deque')

--
-- Input class (event source)
--
local Input = {}
Input.__index = Input

function Input.new(o)
  local o = setmetatable(o or {}, Input)

  -- determine which device to use
  if not o.device then
    if o.name then
      -- attempt to find the midi device by name
      for i,v in ipairs(midi.vports) do
        if sky.starts_with(v.name, o.name) then
          o.device = midi.connect(i)
        end
      end
    else
      o.device = midi.connect(1)
    end
  end

  -- set defaults
  --o.device = o.device or midi.connect(1)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  if o.device == nil then
    print("warning: input not connected to device " .. o.name )
    return o
  end

  -- install device event handler
  o.device.event = function(data)
    o:on_midi_event(data)
  end

  return o
end

function Input:on_midi_event(data)
  if not self.enabled or self.chain == nil then
    -- nothing to do
    return
  end

  local event = midi.to_msg(data)
  if event ~= nil then
    self.chain:process(event)
  end
end


-- allow this input to invoke callbacks
function Input:enable()
  self.enabled = true
end

-- temporarily stop this input from invoking callbacks
function Input:disable()
  self.enabled = false
end

-- perminantly remove this input from receiving further events
function Input:cleanup()
  self:disable()
  if self.device then
    self.device:cleanup()
  end
end

--
-- Output class (event sink)
--
local Output = {}
Output.__index = Output

function Output.new(o)
  local o = setmetatable(o or {}, Output)

  -- defaults
  o.device = o.device or midi.connect(2)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  return o
end

function Output:process(event, output)
  local t = event.type
  if self.enabled and (t ~= nil) then
    -- filter out non-midi events
    if sky.type_names[t] ~= nil then
      self.device:send(event)
    end
  end

  -- pass events on
  output(event)
end


--
-- Clock class (event source)
--
local Clock = {}
Clock.__index = Clock

function Clock.new(o)
  local o = setmetatable(o or {}, Clock)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  o.ch = o.ch or 0

  if o.metro == nil then
    o.metro = metro.init()
  end

  -- setup metro timing and callback
  o.stage = o.stage or 1
  o.interval = o.interval or 1
  o.metro.event = function(stage)
    o.stage = stage
    o:fire(stage)
  end

  return o
end

function Clock:enable()
  self.enabled = true
end

function Clock:disable()
  self.enabled = false
end

function Clock:start()
  -- FIXME: why is the first stage always 1 if the init_stage value is 0?
  self.metro:start(self.interval, -1, self.stage)
  self.chain:process(sky.mk_start(self.ch))
end

function Clock:reset()
  -- TODO: implement this, reset stage to 0 yet retain the same tempo?
  -- or immediately reset?
  self.stage = 0
end

function Clock:stop()
  self.metro:stop()
  self.chain:process(sky.mk_stop(self.ch))
end

function Clock:fire(stage)
  if self.enabled then
    self.chain:process(sky.mk_clock(stage, self.ch))
  end
end

function Clock:cleanup()
  -- ?? metros do need deallocation?
  self.metro.stop()
end


--
-- Chain class
--
local Chain = {}
Chain.__index = Chain

function Chain.new(devices)
  local o = setmetatable({}, Chain)
  o.bypass = false
  o.devices = devices or {}

  -- rip through devices and if there are functions wrap them in a
  -- generic processor object which supports bypass etc.
  for i, d in ipairs(o.devices) do
    if type(d) == 'function' then
      o.devices[i] = sky.Func.new(d)
    end
  end

  o._state = {}
  o._buffers = { Deque.new(), Deque.new() }
  return o
end

function Chain:process(event)
  if self.bypass then
    return
  end

  local state = self._state
  local source = self._buffers[1]
  local sink = self._buffers[2]

  source:clear()
  sink:clear()

  local output = function(event)
    sink:push_back(event)
  end

  -- populate the source event queue with the event to process
  source:push_back(event)

  for i, processor in ipairs(self.devices) do
    event = source:pop()
    while event do
      -- print("\ndevice:", i, "event:", event, "processor:", processor)
      processor:process(event, output, state)
      event = source:pop()
      -- print("sink c:", sink:count())
    end

    -- swap input/output buffers
    local t = source
    source = sink
    sink = t

    -- event = source:pop()
    if source:count() == 0 then
      -- no more events to process, end chain processing early
      -- print("breaking out of process loop")
      break
    end
  end

  -- return output buffer of last processor
  return source
end

function Chain:run(events)
  local output = Deque.new()
  for i, ein in ipairs(events) do
    local r = self:process(ein)
    if r ~= nil then
      -- flatten output
      output:extend_back(r)
    end
  end
  return output:to_array()
end



--
-- module
--

return {
  -- objects
  Input = Input.new,
  Output = Output.new,
  Chain = Chain.new,
  Clock = Clock.new,

  -- debug
  __input_count = input_count,
  __inputs = inputs,
}
