-- Run with: nvim --headless -u NONE -l scripts/test-rex-hermes.lua /path/to/generated/dev-config.lua
-- Isolated API results: never creates a terminal or navigates a real client.
local run
local sessions, windows, api_error
local selected
local fake
fake = {
  bind = function() end,
  action = function(action)
    if action.name == "hermes_open" then run = action.run end
  end,
  exec = function(command)
    local execute = assert(loadstring(command[#command]))
    local destination = setmetatable({
      client = { queue = function(_, target)
        selected = target
      end },
    }, { __index = fake })
    setfenv(execute, setmetatable({ rex = destination }, { __index = _G }))
    return { ok = true, stdout = vim.json.encode(execute()) }
  end,
  json = { decode = vim.json.decode },
  call = function(method)
    if api_error then return nil, api_error end
    if method == "session.list" then return { sessions = sessions } end
    if method == "session.view" then return { windows = windows } end
    if method == "session.new_window" then error("Unexpected terminal creation", 0) end
    return {}
  end,
  client = { queue = function()
    error("Session was selected on the Mac instead of homelab", 0)
  end },
}
local config = assert(loadfile(assert(arg[1], "Pass the generated dev-config.lua path")))
setfenv(config, setmetatable({ rex = fake }, { __index = _G }))()
assert(run, "Hermes action missing")

local function fails(message, context)
  local ok, err = pcall(run, context or { client_id = "test-client" })
  assert(not ok and tostring(err):find(message, 1, true), message .. ": " .. tostring(err))
end
sessions = { { label = "ai dev env", session_id = "wrong-case" } }
fails("AI DEV ENV session not found")
sessions = {
  { label = "AI DEV ENV", session_id = "one" },
  { label = "AI DEV ENV", session_id = "two" },
}
fails("Multiple AI DEV ENV sessions")
sessions = { sessions[1] }
windows = {
  { label = "HERMES", window_id = "one" },
  { label = "HERMES", window_id = "two" },
}
fails("Multiple HERMES windows")
fails("requires a native client", {})
api_error = "session listing failed"
fails(api_error)
api_error = nil
-- A retained, exited terminal is still the persistent tab, not permission to respawn.
windows = { { label = "HERMES", window_id = "exited-window" } }
assert(run({ client_id = "test-client" }).window_id == "exited-window")
assert(selected.session_id == "one" and selected.window_id == "exited-window")
print("Hermes safety checks passed: missing/ambiguous sessions, duplicate tabs, client requirement, API failure, retained exited tab")
