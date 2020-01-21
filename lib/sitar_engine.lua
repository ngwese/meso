--
-- sitar_engine.lua
--
-- Engine parameters and functions
--
-- @module SitarEngine
-- @release v0.1
-- @author Greg Wuller

local MusicUtil = require "musicutil"
local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local SitarEngine = {}

local specs = {}

-- TODO: add controls

SitarEngine.specs = specs

function SitarEngine.init_tuning(chikari_freqs, tarafdar_freqs, base)
  if base == nil then
    base = MusicUtil.note_num_to_freq(48)
  end
  engine.beginTuning()
  for i,f in ipairs(chikari_freqs) do
    engine.addChikariFreq(base * f)
  end
  for i,f in ipairs(tarafdar_freqs) do
    engine.addTarafdarFreq(base * f)
  end
  engine.endTuning()
end

function SitarEngine.add_params()
  -- TODO: add params
end

return SitarEngine
