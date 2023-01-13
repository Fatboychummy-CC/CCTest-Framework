-- Calculate the path to self for module requiring.
local modulesPath = ...

-- loop backwards through module path string.
for i = #modulesPath, 1, -1 do
  -- if we find a dot, remove the end of the string up until the dot.
  if modulesPath:sub(i, i) == '.' then
    modulesPath = modulesPath:sub(1, i)
    break
  end

  -- if i is one, we've gone all the way through and haven't found a dot. Add a dot to the end of it.
  if i == 1 then
    modulesPath = modulesPath .. '.'
  end
end

---@class suite

local module = {
  loaded = {},
  tests = {},
  disabled = 0
}

local function badModule(module, versionMinimum)
  local dir = fs.getDir(shell.getRunningProgram())
  term.setTextColor(colors.orange)
  print(string.format("Module '%s' does not exist on pre-%s minecraft versions. This test framework will not work on your version of minecraft without doing the following:"
    , module, versionMinimum))
  print()
  print("1.", "Go to https://github.com/Squiddev-CC/CC-Tweaked")
  print("2.", string.format("Click 'Go To File', and search for '%s.lua'.", module:gsub("%.", "/")))
  print("3.", "Click 'Raw', then copy the link.")
  print("4.", string.format("Run 'wget LINK_HERE %s/%s.lua'", dir, module:gsub("%.", "/")))
  print()
  error("Missing core modules.", 0)
end

local ok, strings = pcall(require, "cc.strings")
if not ok then
  badModule("cc.strings", "1.16")
end
local ok2, expect = pcall(require, "cc.expect")
if not ok2 then
  badModule("cc.expect", "1.12")
end
expect = expect.expect
local Expectations = require(modulesPath .. "Expectations")
local Test = require(modulesPath .. "Test")
local toInject = {}
local dummyTerminate = "DUMMY"
local verbose = false
local hasVPrinted = false

_G.DISABLED = {} --- global for disabled tests

function _G.DUMMY_TERMINATE() --- Terminate but do not kill the test program.
  return "terminate", dummyTerminate
end

function _G.verbosePrint(...)
  if verbose then
    if not hasVPrinted then
      print()
      hasVPrinted = true
    end
    print(...)
  end
end

--- This functions builds the info line for the current test, ie:
--- [ RUN ] testName
--- [ FAIL] testName
--- [ERROR] testName
--- ... so on
--- generates blit line bg and fg colors as well
---@param name string The name of the info line.
---@param status number The status of the test.
---@return string text The status text.
---@return string foreground The blit foreground.
---@return string background The blit background.
local function buildInfoLine(name, status)
  expect(1, name, "string")
  expect(2, status, "number")

  local formatInfo = "[%s]: %s"
  local formatFG = "0%s000%s"
  local formatBG = "f%sfff%s"
  local statusString, statusFG, statusBG
  if status == Test.STATUS.LOADED then
    statusString = " RDY "
    statusFG = "99999"
    statusBG = "fffff"
  elseif status == Test.STATUS.LOADING then
    statusString = "LDING"
    statusFG = "88888"
    statusBG = "fffff"
  elseif status == Test.STATUS.RUNNING then
    statusString = " RUN "
    statusFG = "00000"
    statusBG = "fffff"
  elseif status == Test.STATUS.OK then
    statusString = "OK   "
    statusFG = "55000"
    statusBG = "fffff"
  elseif status == Test.STATUS.FAIL then
    statusString = " FAIL"
    statusFG = "0eeee"
    statusBG = "fffff"
  elseif status == Test.STATUS.ERROR then
    statusString = "ERROR"
    statusFG = "eeeee"
    statusBG = "fffff"
  else
    statusString = "?????"
    statusFG = "44444"
    statusBG = "fffff"
  end

  return string.format(formatInfo, statusString, name),
      string.format(formatFG, statusFG, string.rep('a', #name)),
      string.format(formatBG, statusBG, string.rep('f', #name))
end

--- write the info about a test.
---@param t test The test to write information for.
local function writeInfo(t)
  local xSize = term.getSize()
  local x, y = term.getCursorPos()
  term.setCursorPos(1, y)
  io.write(string.rep(' ', xSize))

  term.setCursorPos(1, y)
  term.blit(buildInfoLine(t.name, t.status))
end

--- if the test failed or errored, print the reason, otherwise just draw a newline
---@param t test The test to print error reason for.
local function finishTest(t)
  print()
  if t.status == Test.STATUS.FAIL then
    print("Test failed:")
    printError(string.format("  %s", table.concat(t.reason, "\n\n  ")))
    print()
    return
  elseif t.status == Test.STATUS.ERROR then
    print("Test failed: Error was thrown in test body.")
    printError(string.format("  %s", table.concat(t.error, "\n\n  ")))
    print()
    return
  end
end

--- Create a test wrapper for a given function.
---@param f function
---@param isAsserted boolean If the test function was asserted.
---@return fun(...:any):boolean, boolean, string test_wrapper The test wrapper which returns the test results.
local function generateWrapper(f, isAsserted)
  return function(...)
    local ok, ret = f(...)
    local assertOk = true
    if isAsserted and not ok then assertOk = false end

    return ok, assertOk, ret
  end
end

for k, v in pairs(Expectations) do
  toInject["EXPECT_" .. k] = generateWrapper(v, false)
  toInject["ASSERT_" .. k] = generateWrapper(v, true)
end

---@type fun():satisfied:true, error:string Pass the test.
toInject.PASS = generateWrapper(function() return true, "" end, false)
---@type fun(reason:string?):satisfied:true, error:string Fail the test, with an optional reason.
toInject.FAIL = generateWrapper(function(reason) return false, reason or "Forceful failure." end, true)

--- Count the number of tests that are loaded.
---@return integer tests The total number of tests.
---@return {suites:table<string,test>} fails The tests that failed, and which suites they are from.
local function countTests()
  local total = 0
  local fails = {
    suites = { n = 0 }
  }
  for i = 1, #module.tests do
    for j, test in ipairs(module.tests[i]) do
      if test.status == Test.STATUS.FAIL or test.status == Test.STATUS.ERROR then
        total = total + 1
        if not fails.suites[test.suite] then
          fails.suites[test.suite] = { n = 0 }
          fails.suites.n = fails.suites.n + 1
        end
        fails.suites[test.suite].n = fails.suites[test.suite].n + 1
        fails.suites[test.suite][#fails.suites[test.suite] + 1] = test
      end
    end
  end

  return total, fails
end

local function splitOn(a, b)
  local t = {}
  for i = 1, #b do
    local x = a:sub(1, #b[i])
    a = a:sub(#b[i] + 1)
    t[i] = x
  end

  return t
end

local function parseArgs(...)
  local args = table.pack(...)

  local data = {
    flags = {},
    args = {}
  }

  for i = 1, args.n do
    local arg = args[i]
    if arg:match("^%-%a") then -- flag, add to flags list
      for j = 2, #arg do
        data.flags[arg:sub(i, i):lower()] = true
      end
    elseif arg:match("^%-%-.+") then -- big-flag
      data.flags[arg:sub(3):lower()] = true
    else -- not a flag, just throw it in the arg list.
      data.args[#data.args + 1] = arg
    end
  end

  return data
end

local function setVerbose(v)
  expect(1, v, "boolean")
  verbose = v
end

--- Print the disabled tests.
local function printDisabled()
  if module.disabled > 0 then
    print()
    term.setTextColor(colors.yellow)
    print(string.format("%d test%s disabled.", module.disabled, module.disabled > 1 and "s are" or " is"))
  end
end

--- Run all of the tests that have been loaded.
---@param ... string The arguments to run the tests with.
function module.runAllTests(...)
  local args         = parseArgs(...)
  local doStackTrace = args.flags.s or args.flags["stack-trace"]
  verbose            = args.flags.v or args.flags.verbose

  local startingTerm = term.current()

  verbosePrint("Verbose logging enabled.")
  if doStackTrace then
    verbosePrint("Stack-trace enabled.")
  end

  verbosePrint("Running all suites.")
  for i = 1, #module.tests do
    module.runSuite(module.tests[i], verbose, doStackTrace)
  end

  term.redirect(startingTerm) -- ensure we got back to the original term.

  verbosePrint("Done running suites. Sorting results.")

  local total, inSuites = countTests()
  if total == 0 then
    print("All tests passed.")
    printDisabled()
    return
  end

  local mx, my = term.getSize()
  local c = term.getTextColor()
  term.setTextColor(colors.orange)
  print(string.format("%d test%s failed from %d suite%s.", total, total > 1 and "s" or "", inSuites.suites.n,
    inSuites.suites.n > 1 and "s" or ""))
  term.setTextColor(c)
  for suiteName, tests in pairs(inSuites.suites) do
    if type(tests) == "table" then
      for i = 1, #tests do
        local txt, fg, bg = "Test %s from %s failed.",
            "00000%s000000%s00000000",
            "fffffffffffffffffff%s"
        local testName = tests[i].name
        txt = txt:format(testName, suiteName)
        fg = fg:format(string.rep('a', #testName), string.rep('b', #suiteName))
        bg = bg:format(string.rep('f', #testName + #suiteName))
        txt = strings.wrap(txt, mx - 2)

        ---@diagnostic disable-next-line
        fg = splitOn(fg, txt) ---@cast fg table

        ---@diagnostic disable-next-line
        bg = splitOn(bg, txt)

        for j = 1, #txt do
          local x, y = term.getCursorPos()
          term.setCursorPos(3, y)
          term.blit(txt[j], fg[j], bg[j])
          print()
        end
      end
    end
  end

  printDisabled()
end

--- Run a single suite of tests.
---@param s suite The test suite.
---@param verbose boolean? Whether or not to print verbose text.
---@param doStackTrace boolean? Whether or not to display a stacktrace on errors.
function module.runSuite(s, verbose, doStackTrace)
  local fg, bg, txt = "0000000%s",
      "fffffff%s",
      "Suite: %s"
  term.blit(txt:format(s.name), fg:format(string.rep('b', #s.name)), bg:format(string.rep('f', #s.name)))
  print()
  print()
  for i = 1, #s do
    local currentTest = s[i]
    local terminated = false
    local x, y = term.getCursorPos()
    local w = window.create(term.current(), 0, 0, 1, 1)
    local _, my = term.getSize()
    local oldTerm = term.redirect(w)
    if verbose then
      term.redirect(oldTerm)
    end

    parallel.waitForAny(
      function()
        while true do
          term.redirect(oldTerm)
          if verbose then
            y = y + 1
            if y > my then
              y = my
              term.scroll(1)
            end
          end
          term.setCursorPos(x, y)
          writeInfo(currentTest)

          if not verbose then
            term.redirect(w)
          end

          hasVPrinted = false
          local ev, a1 = os.pullEventRaw("test_checkpoint")

          if ev == "terminate" and a1 ~= dummyTerminate then
            error("Terminated testing.", 0)
          end
          if verbose then
            write(" ## " .. tostring(a1))
          end
        end
      end,
      function()
        currentTest:Run(toInject, verbose, doStackTrace, w)
      end
    )

    term.redirect(oldTerm)
    if terminated then
      error("Terminated testing.")
    end

    writeInfo(currentTest)
    finishTest(currentTest)
  end
  print()
end

--- Create a new suite.
---@param suiteName string The name of the suite
function module.newSuite(suiteName)
  local suite = { finished = false, name = suiteName }
  module.tests[#module.tests + 1] = suite

  local currentName, loadBody

  --- Load the name into memory
  ---@param name string The name of the test to be loaded.
  ---@return fun(f:{[1]:function}|function)
  local function loadName(name)
    expect(1, name, "string")
    suite.finished = false

    currentName = name

    return loadBody
  end

  --- Load the body, then create the test and add it to the suite.
  ---@param f {[1]:function}|function The function to test.
  ---@return fun(name:string)
  loadBody = function(f)
    if type(f) == "table" then
      if f == DISABLED then
        module.disabled = module.disabled + 1
        return loadName
      end
      f = f[1]
    end
    expect(1, f, "table", "function")

    suite[#suite + 1] = Test.new(f, currentName, suiteName)

    suite.finished = true
    return loadName
  end

  -- return the name loader.
  return loadName
end

return module
