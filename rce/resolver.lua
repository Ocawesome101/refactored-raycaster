-- path resolver

local expect = require("cc.expect").expect

return function(path)
  expect(1, path, "string")
  if path:sub(1,1) ~= "/" then
    path = fs.combine(shell.getDir(), path)
  end
  return path
end
