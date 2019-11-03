-- powermate test

local powermate = include('meso/lib/powermate')

pm = powermate.connect(1)
pm.key = function(num, value)
  print("key: ", num, value)
end
pm.enc = function(num, delta)
  print("enc: ", num, delta)
end

function enc(num, delta)
  print("[enc]: ", num, delta)
end

function key(num, z)
  print("[key]: ", num, z)
end

