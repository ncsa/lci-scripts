-----------------------------------------------------------------------
-- BLAME: Alan <acchapm1@asu.edu>
-- BUILD_DATE: 2024-12-16
-- BUILD_PATH: /packages/apps/ollama/0.15.6
-----------------------------------------------------------------------

-- Define module metadata
local app_path     = "/packages/apps/ollama"
local _name        = "Ollama"
local _version     = "0.15.6"
local _description = [===[

  Get up and running with large language models.
  
  For more information, visit: https://github.com/ollama/ollama/tree/main/docs

]===]

local _help  = string.format([===[

  Name: %s
  Version:  %s

  ## Description ##
  %s
]===],
  _name,
  _version,
  _description
)

whatis(_help)
help(_help)

socket = require "socket"
local host = socket.dns.gethostname()
local user = os.getenv("LOGNAME")
local pkgName = myModuleName()
local ver = "0.15.6"

-- Set the environment variables for Ollama
setenv("LMOD_COLORIZE", "yes")
setenv("OLLAMA_DEBUG", "0")
setenv("OLLAMA_ORIGINS", "*")
setenv("OLLAMA_KEEP_ALIVE ", "30")
setenv("OLLAMA_MODELS", pathJoin("/scratch", user, ".ollama/models"))
setenv("OLLAMA_HOME", pathJoin("/scratch", user, ".ollama"))
setenv("OLLAMA_KEEP_ALIVE", "10m")

-- Prepend paths to the system PATH
prepend_path("PATH", pathJoin(app_path, ver, "/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app_path, ver, "/lib/ollama"))

if (mode() == "load") then
-- Ollama Port stuffs Start
-- Function to check if a port is available
local function is_port_available(port)
        local tcp = assert(socket.tcp())
        tcp:settimeout(1)

        local result = tcp:bind("*", port)
        tcp:close()

        return result ~= nil
end

-- Function to find the first available port in a range
local function find_first_available_port(start_port, end_port)
        for port = start_port, end_port do
                if is_port_available(port) then
                        return port
                end
        end
        return nil -- Return nil if no available port is found
end

-- Define the port range to check
local start_port = 11434
local end_port = 11534

-- Find and print the first available port
local available_port = find_first_available_port(start_port, end_port)
local port = available_port
-- End find availalbe port
local _ollamahost = "http://" .. host .. ":" .. port
-- Update Environment Variables with new port number. 
setenv("OLLAMA_HOST", host .. ":" .. port)
-- Ollama Port stuffs End

-- Optional: Add aliases for convenience
set_alias("ollama-start", "sh /packages/apps/ollama/scripts/start.sh")
set_alias("ollama-stop", "sh /packages/apps/ollama/scripts/stop.sh")

  local _loaded = string.format([===[
========================================================================
Loaded: %s %s
========================================================================

Ollama Host for this session %s

To start the ollama server in the background run 
   ollama-start

To stop the ollama server run 
   ollama-stop

*************************************************
NOTE Ollama will not run on a login node, start
an interactive session to run ollama ie
  interactive -G 1 -t 0-4:00                     
That will start an session for 4 hours with a GPU
*************************************************
    ]===],
    _name,
    _version,
    _ollamahost
  )
  LmodMessage(_loaded)
end

if (mode() == "unload") then

-- remove aliases added on load
unset_alias("ollama-start")
unset_alias("ollama-stop")
-- end aliases

  local _unloaded = string.format([===[
========================================================================
Unloaded: %s %s
========================================================================
     ]===],
     _name,
     _version
   )
   LmodMessage(_unloaded)
end
