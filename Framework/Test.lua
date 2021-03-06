local expect = require "cc.expect".expect

-- small test object
local test = {
  STATUS = {
    LOADED = 1,
    RUNNING = 2,
    OK = 3,
    FAIL = 4,
    ERROR = 5,
    LOADING = 6
  }
}
local testmt = {__index = {}}
function testmt.__index:Fail(reason)
  self.status = test.STATUS.FAIL
  table.insert(self.reason, reason)
end
function testmt.__index:Error(reason)
  self.status = test.STATUS.ERROR
  table.insert(self.error, reason)
end
function testmt.__index:Ok()
  self.status = test.STATUS.OK
end
function testmt.__index:Stop()
  self.running = false
end

local function checkpoint(checkpointType)
  os.queueEvent("test_checkpoint", checkpointType)
  os.pullEventRaw("test_checkpoint") -- allow for other coroutines to update.
end

local function generateTestWrapper(test, toInject)
  local _injecting = {}
  for k, v in pairs(toInject) do
    _injecting[k] = function(...)
      local testOk, assertOk, reason = v(...)
      if not testOk then
        local traceback = debug.traceback()
        local func, file = traceback:match("in function '(.-)'") or "UNKNOWN",
                    traceback:match(".-\n.-\n%s(%S-%:%d+%:)") or "Unknown file:"
        local formatter = "%s%s: %s"
        test:Fail(formatter:format(file, func, reason))
      end
      if not assertOk then
        test:Stop()
      end

      -- allow switching between running functions, and termination.
      checkpoint(k)
    end
  end

  return _injecting
end

function testmt.__index:Run(injectedEnv, verbose, doStackTrace, redirectObj)
  expect(1, injectedEnv, "table")
  self.status = test.STATUS.LOADED
  checkpoint("INIT")
  local wrapperInjection = generateTestWrapper(self, injectedEnv)

  for k, v in pairs(wrapperInjection) do
    _ENV[k] = v
  end

  self.running = true
  self.status = test.STATUS.RUNNING

  checkpoint("INITTED")

  parallel.waitForAny(
    function()
      while true do
        os.pullEventRaw("test_checkpoint")
        if self.running == false then
          return
        end
      end
    end,
    function()
      local ok, err
      if doStackTrace then
        ok, err = xpcall(self.func, debug.traceback)
      else
        ok, err = pcall(self.func)
      end
      if not ok then
        self:Error(err)
        self:Stop()
      elseif self.status ~= test.STATUS.FAIL then
        self:Ok()
      end
    end
  )

  for k in pairs(wrapperInjection) do
    _ENV[k] = nil
  end

  checkpoint("END")

  return self
end

function test.new(f, name, suite)
  local obj = {
    name = name,
    suite = suite,
    error = {},
    reason = {},
    status = test.STATUS.LOADING,
    func = f,
    running = false
  }

  return setmetatable(obj, testmt)
end

return test
