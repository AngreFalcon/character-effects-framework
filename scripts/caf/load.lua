local vfs = require('openmw.vfs')

local configFiles

local function loadConfigFiles()
   for fileName in vfs.pathsWithPrefix("scripts/caf") do
      local file = vfs.open(fileName)
      if file ~= nil then
         configFiles[file.fileName] = file:read("*all")
      end
   end
end

return {
   engineHandlers = {
      onContentFilesLoaded = function()
         loadConfigFiles()
      end,
   },
   configFiles,
}
