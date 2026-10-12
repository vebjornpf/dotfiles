local M = {}

function M.setup()
  require('features.ui').setup()
  require('features.shortcuts').setup()
end

return M
