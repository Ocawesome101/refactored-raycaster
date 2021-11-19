-- ComputerCraft input scheme --

local lib = {keys=keys}

local lastTimerID
function lib.tick(i)
  if not lastTimerID then
    lastTimerID = os.startTimer(0)
  end

  local sig, code, rep = os.pullEventRaw()
  if sig == "terminate" then
    return true
  elseif sig == "timer" and code == lastTimerID then
    lastTimerID = nil
  elseif sig == "key" and not rep then
    i.pressed[code] = true
  elseif sig == "key_up" then
    i.pressed[code] = false
  end
end

return lib
