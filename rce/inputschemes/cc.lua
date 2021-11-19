-- ComputerCraft input scheme --

local lib = {}

local lastTimerID
function lib.tick(i)
  i.keys = i.keys or keys
  if not lastTimerID then
    lastTimerID = os.startTimer(0)
  end

  local sig, code, rep = os.pullEventRaw()
  if sig == "timer" and code == lastTimerID then
    lastTimerID = nil
  elseif sig == "key" and not rep then
    pressed[code] = true
  elseif sig == "key_up" then
    pressed[code] = false
  end
end

return lib
