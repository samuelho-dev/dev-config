-- Run with: nvim --headless -u NONE -l scripts/test-rex-hermes.lua /path/to/generated/dev-config.lua
-- Isolated API results: never creates a terminal or navigates a real client.
local run
local sessions, windows, api_error
local fake = {
  bind = function() end,
  action = function(action)
    if action.name == "hermes_open" then run = action.run end
  end,
  call = function()
    if api_error then return nil, api_error end
    return { sessions = sessions }
  end,
  session = {
    view = function() return { windows = windows } end,
    new_window = function() error("Unexpected terminal creation", 0) end,
  },
  client = { queue = function() end },
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
print("Hermes safety checks passed: missing/ambiguous sessions, duplicate tabs, client requirement, API failure, retained exited tab")
