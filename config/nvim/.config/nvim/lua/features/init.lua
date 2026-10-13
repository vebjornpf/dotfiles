local M = {}

function M.setup()
  require('features.ui').setup()
  require('features.shortcuts').setup()
  require('features.file_paths').setup()
end

return M
