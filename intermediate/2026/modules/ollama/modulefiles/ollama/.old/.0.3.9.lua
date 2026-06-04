-- ollama.lua
-- This is a Lua module file for setting up the Ollama environment
-- It includes environment variables typically supported by Ollama

help([[
This module sets up the environment for Ollama.
]])

-- Define the module
whatis("Name: Ollama")
whatis("Version: 0.3.9")
whatis("Category: AI Platform")
whatis("Description: Ollama is an AI platform for machine learning and data processing.")

local host = os.getenv("HOSTNAME")
local user = os.getenv("LOGNAME")

-- Set the environment variables for Ollama
setenv("OLLAMA_HOST", host)
setenv("OLLAMA_DEBUG", "0")
setenv("OLLAMA_MODELS", pathJoin("/scratch", user, ".ollama/models"))
setenv("OLLAMA_HOME", pathJoin("/scratch", user, ".ollama/"))
setenv("OLLAMA_KEEP_ALIVE", "10m")

-- Prepend paths to the system PATH
prepend_path("PATH", "/packages/apps/ollama/0.3.9/bin")
prepend_path("LD_LIBRARY_PATH", "/packages/apps/ollama/0.3.9/lib")

-- Load any dependencies if needed
-- load("dependency_module")

-- Optional: Add aliases for convenience
-- set_alias("ollama_start", "sh /path/to/ollama/bin/start.sh")
-- set_alias("ollama_stop", "sh /path/to/ollama/bin/stop.sh")


-- Print a message to indicate the module has been loaded
if (mode() == "load") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.9 loaded.")
    LmodMessage(" ")
    LmodMessage("=====================")
end

-- Print a message to indicate the module has been unloaded
if (mode() == "unload") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.9 unloaded.")
    LmodMessage(" ")
    LmodMessage("=====================")
end

