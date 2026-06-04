-----------------------------------------------------------------------
-- BLAME: Alan <acchapm1@asu.edu>
-- BUILD_DATE: 2024-09-26
-- BUILD_PATH: /packages/apps/build/ollama/0.3.12
-----------------------------------------------------------------------

-- Define module metadata
local app_path     = "/packages/apps/ollama"
local _name        = "Ollama"
local _version     = "0.3.12"
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
local ver = "0.3.12"

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
--- End find port



-- Set the environment variables for Ollama
setenv("OLLAMA_HOST", host)
setenv("OLLAMA_DEBUG", "0")
setenv("OLLAMA_MODELS", pathJoin("/scratch", user, ".ollama/models"))
setenv("OLLAMA_HOME", pathJoin("/scratch", user, ".ollama"))
setenv("OLLAMA_KEEP_ALIVE", "10m")

-- Prepend paths to the system PATH
prepend_path("PATH", pathJoin(app_path, ver, "/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app_path, ver, "/lib/ollama"))

-- Load any dependencies if needed
-- load("dependency_module")

-- Optional: Add aliases for convenience
set_alias("ollama-start", "sh /packages/apps/ollama/scripts/start.sh")
set_alias("ollama-stop", "sh /packages/apps/ollama/scripts/stop.sh")


-- Print a message to indicate the module has been loaded
if (mode() == "load") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.12 loaded.")
    LmodMessage(" ")
    LmodMessage("To start ollama serve in the background run ")
    LmodMessage("ollama-start  ")
    LmodMessage(" ")
    LmodMessage("To stop ollama serve run ")
    LmodMessage("ollama-stop ")
    LmodMessage(" ")
    LmodMessage("*************************************************")
    LmodMessage("NOTE Ollama will not run on a login node, start ")
    LmodMessage("an interactive session to run ollama ie")
    LmodMessage("  interactive -G 1 -t 0-4:00")
    LmodMessage("That will start an session for 4 hours with a GPU ")
    LmodMessage("*************************************************")
    LmodMessage(" ")
    LmodMessage("=====================")
end

-- Print a message to indicate the module has been unloaded
if (mode() == "unload") then
    LmodMessage("=====================")
    LmodMessage(" ")
    LmodMessage("Ollama 0.3.12 unloaded.")
    LmodMessage(" ")
    LmodMessage("=====================")
end

