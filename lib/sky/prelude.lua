
-- setup the global sky module for devices use without having to redundently
-- require/include the core

local function import(target, module)
  for k, v in pairs(module) do
    target[k] = v
  end
end

sky = {
  __loaded = {},
}

function sky.use(path, reload)
  if sky.__loaded[path] == nil or reload then
    local module = include(path)
    sky.__loaded[path] = module
    import(sky, module)
  end
  return sky.__loaded[path]
end

sky.use('meso/lib/sky/core/event')
sky.use('meso/lib/sky/core/process')
sky.use('meso/lib/sky/device/utility') -- needed by Chain
sky.use('meso/lib/sky/device/virtual')

return sky

