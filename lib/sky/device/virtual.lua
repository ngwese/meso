local Observers = {}

local function _add(name, receiver)
  local existing = Observers[name]
  if existing == nil then
    existing = {}
    Observers[name] = existing
  end
  -- set like behavior
  local listening = false
  for _, r in ipairs(existing) do
    if r == receiver then
      listening = true
      break
    end
  end
  if not listening then
    table.insert(existing, receiver)
  end
end

local function _remove(name, receiver)
  local existing = Observers[name]
  if existing then
    table.remove(existing, receiver)
  end
end

--
-- Receive
--

local Receive = {}
Receive.__index = Receive

function Receive.new(sender_name, chain)
  local o = setmetatable({}, Receive)
  o.from = sender_name
  o.chain = chain
  _add(o.from, o)
  return o
end

function Receive:process(event)
  self.chain:process(event)
end

--
-- Send
--

local Send = {}
Send.__index = Send

function Send.new(name)
  local o = setmetatable({}, Send)
  o.to = name
  return o
end

function Send:process(event, output, state)
  output(event) -- pass events through to this chain
  local listeners = Observers[self.to]
  if listeners then
    for _, r in ipairs(listeners) do
      r:process(event)
    end
  end
end

return {
  Receive = Receive.new,
  Send = Send.new,
}


