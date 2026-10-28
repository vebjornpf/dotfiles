local M = {}

function M.setup()
  require('features.ui').setup()
  require('features.shortcuts').setup()
  require('features.file_paths').setup()
  require('features.lsp').setup()
  require('features.jar_sources').setup()
  require('features.gradle').setup()
  require('features.agent_comments').setup()
end

return M
