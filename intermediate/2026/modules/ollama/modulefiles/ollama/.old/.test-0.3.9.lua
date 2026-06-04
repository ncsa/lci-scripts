-- ollama.lua
-- This is a Lua module file for setting up the Ollama environment
-- It includes environment variables typically supported by Ollama

socket = require "socket"

help([[
This module sets up the environment for Ollama.
]])

-- Define the module
whatis("Name: Ollama")
whatis("Version: 0.3.10")
whatis("Category: AI Platform")
whatis("Description: Ollama is an AI platform for machine learning and data processing.")

-- local host = os.getenv("HOSTNAME")
local host = socket.dns.gethostname()
local user = os.getenv("LOGNAME")
local pkgName = myModuleName()
local ver = "0.3.10"
local app_path = "/packages/apps/ollama"

-- Set the environment variables for Ollama
setenv("OLLAMA_HOST", host)
setenv("OLLAMA_DEBUG", "0")
setenv("OLLAMA_MODELS", pathJoin("/scratch", user, ".ollama/models"))
setenv("OLLAMA_HOME", pathJoin("/scratch", user, ".ollama"))
setenv("OLLAMA_KEEP_ALIVE", "10m")

-- Prepend paths to the system PATH
prepend_path("PATH", pathJoin(app_path, ver, "/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app_path, ver, "/lib"))

-- Load any dependencies if needed
-- load("dependency_module")

-- Auto load and unload ollama serve when module is loaded.
-- if (mode() == "load") then
--    source_sh("bash", "/packages/apps/ollama/0.3.10/scripts/start.sh")
-- end
-- if (mode() == "unload") then
--    source_sh("bash", "/packages/apps/ollama/0.3.10/scripts/stop/sh")
-- end


-- Optional: Add aliases for convenience
set_alias("ollama-start", "sh /packages/apps/ollama/0.3.10/scripts/start.sh")
set_alias("ollama-stop", "sh /packages/apps/ollama/0.3.10/scripts/stop.sh")


-- Print a message to indicate the module has been loaded
if (mode() == "load") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.10 loaded.")
    LmodMessage(" ")
    LmodMessage("To start ollama serve in the background run ")
    LmodMessage("ollama-start  ")
    LmodMessage(" ")
    LmodMessage("To stop ollama serve run ")
    LmodMessage("ollama-stop ")
    LmodMessage(" ")
    LmodMessage("=====================")
end

-- Print a message to indicate the module has been unloaded
if (mode() == "unload") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.10 unloaded.")
    LmodMessage(" ")
    LmodMessage("=====================")
end

