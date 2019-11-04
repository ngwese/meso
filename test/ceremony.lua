local mu = require('musicutil')
local hs = require('awake/lib/halfsecond')

engine.name = 'Ceremony'

local max_voice = 16
local voice_next = 1

local midi_in
local midi_out

function on_midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == 'note_on' then
    local hz = mu.note_num_to_freq(msg.note)
    local trig = 0.3
    local sing = 0.0
    local amp = 10.0
    engine.start(voice_next, hz, trig, sing, amp, 0.2, 0.2)
    voice_next = (voice_next + 1) % max_voice
  end
end

function connect()
  midi_in = midi.connect(1)
  midi_in.event = on_midi_event
  midi_out = midi.connect(2)
end

function init()
  hs.init()
  connect()
end