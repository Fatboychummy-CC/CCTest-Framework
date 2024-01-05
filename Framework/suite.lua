--- This module compiles test data into a table of tests.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]
local test_runner = require "Framework.runner"
local methods = require "Framework.assertions"
local logger = require "Framework.logger"

---@alias test_status
---| '"pass"' # The test passed.
---| '"fail"' # The test failed.
---| '"error"' # The test errored.
---| '"disabled"' # The test was disabled (and will be skipped).
---| '"new"' # The test has not been run yet.
---| '"running"' # The test is currently running.

---@class identifier_table : table This is an empty table that can be used to identify specific things, mainly used as a comparison object.

---@class modifier_table
---@field action string The action to perform.
---@field value any The value to perform the action with.

---@class suite_modifiers
---@field ONLY identifier_table A test marked as ONLY will be the only test run (unless multiple tests are marked as ONLY, in which case all of them will be run).
---@field DISABLE identifier_table A test marked as DISABLE will be skipped.
---@field TIMEOUT fun(timeout: number): modifier_table A test marked as TIMEOUT will be given a timeout. If the test runs for longer than the timeout, it will be marked as a failed test.
---@field REPEAT fun(repeat_count: number): modifier_table A test marked as REPEAT will be repeated the specified number of times.
---@field REPEAT_TIMEOUT fun(repeat_count: number, timeout: number): modifier_table A test marked as REPEAT_TIMEOUT will be repeated the specified number of times, and if the entire batch takes longer than the timeout, it will be marked as a failed test.
---@field REPEAT_UNTIL_FAIL identifier_table A test marked as REPEAT_UNTIL_FAIL will be repeated until it fails. Useful for debugging things that only occur sometimes.
---@field POST_DELAY fun(delay: number): modifier_table A test marked as POST_DELAY will be delayed by the specified number of seconds after it has finished running.

---@class suites
--- ```lua
--- local mySuite = suite.suite "My Suite"
---   "Test name" (function()
---     -- Test code here
---   end)
--- ```
---@field suites suite[] The suites that have been loaded.
---@field MODS suite_modifiers The global test modifiers that can be used.
local suite = {
  MODS = {
    ONLY = {},
    DISABLE = {},
    TIMEOUT = function(timeout)
      return {
        action = "TIMEOUT",
        value = timeout
      }
    end,
    REPEAT = function(repeat_count)
      return {
        action = "REPEAT",
        value = repeat_count
      }
    end,
    REPEAT_TIMEOUT = function(repeat_count, timeout)
      return {
        action = "REPEAT_TIMEOUT",
        value = {
          repeat_count = repeat_count,
          timeout = timeout
        }
      }
    end,
    POST_DELAY = function(delay)
      return {
        action = "POST_DELAY",
        value = delay
      }
    end,
    REPEAT_UNTIL_FAIL = {}
  },
  suites = {}
}

--- Check if an identifier is valid.
---@param value any The value to check.
---@return string? modifier The modifier that was found, or nil if none was found.
---@return any value The additional value of the modifier, if one exists.
local function check_identifier(value)
  if type(value) == "table" then
    if next(value) == nil then
      -- Table is empty, check if it exists within the modifiers table.
      for name, v in pairs(suite.MODS) do
        if v == value then
          return name
        end
      end
    else
      -- Table is not empty, check if it is a modifier.
      if value.action and suite.MODS[value.action] then
        return value.action, value.value
      end
    end
  end
end

--- Create a new test suite.
---@param name string The name of the suite.
---@return suite suite The new suite.
function suite.suite(name)
  expect(1, name, "string")

  ---@class suite
  ---@field name string The name of the suite.
  ---@field tests test_data[] The tests in the suite.
  ---@operator call(string): fun(...:identifier_table|modifier_table|fun()): suite
  local new_suite = {
    name = name,
    tests = {}
  }

  table.insert(suite.suites, new_suite)

  --- Run the suite.
  ---@param dont_log_results boolean? If true, the results will not be logged. Used mainly in the suites.run_all_suites function.
  function new_suite.run(dont_log_results)
    logger.new_suite(new_suite.name, #new_suite.tests)

    -- Check through the suite for ONLY tests.
    local only_tests = {}

    for _, test in ipairs(new_suite.tests) do
      if test.modifiers.ONLY then
        table.insert(only_tests, test)
      end
    end

    -- If there are ONLY tests, run them.
    if #only_tests > 0 then
      print("Some tests are marked as ONLY, running only those.")
      for _, test in ipairs(only_tests) do
        test.run()
      end
    else
      -- Otherwise, run all tests.
      for _, test in ipairs(new_suite.tests) do
        test.run()
      end
    end

    -- Log the results
    if dont_log_results then
      logger.close_suite(new_suite.name)
    else
      logger.log_results({new_suite})
    end
  end

  --- Insert a test (with its modifiers) into the suite.
  ---@param name string The name of the test.
  ---@param ... identifier_table|modifier_table|fun() The test to insert (or its modifiers).
  ---@return suite suite The suite, for chaining. 
  local function insert_test(name, ...)
    expect(1, name, "string")

    ---@class test_data
    ---@field name string The name of the test.
    ---@field coro thread The coroutine for the test.
    ---@field status test_status The status of the test.
    ---@field error string|nil The error message, if the test errored.
    ---@field enabled boolean Whether the test is enabled.
    ---@field modifiers modifier_table[] The modifiers for the test.
    ---@field failures string[] The failure messages, if the test failed.
    local test = {
      name = name,
      status = "new",
      error = nil,
      enabled = true,
      modifiers = {},
      failures = {},
      test_env = _ENV._cctest_env or _ENV
    }

    --- Run the test.
    function test.run()
      test_runner.setup()
      if not test.test_env._cctest_injected then
        methods.inject(test.test_env)
      end
      return test_runner.run_test(test, logger)
    end

    local args = table.pack(...)

    -- Determine what modifiers are being used.
    for i = 1, args.n do
      local arg = args[i]
      if type(arg) == "table" then
        -- If the argument is a table, it's either an identifier or a modifier, we should collect it.
        local modifier, value = check_identifier(arg)
        if modifier then
          test.modifiers[modifier] = value or true
        else
          error(("Invalid modifier received as argument %d."):format(i), 2)
        end
      elseif type(arg) == "function" then
        test.coro = coroutine.create(arg)
      else
        expect(i, arg, "table", "function")
      end
    end

    -- If the test is marked as disabled, disable it.
    if test.modifiers.DISABLE then
      test.enabled = false
      test.status = "disabled"
    end

    table.insert(new_suite.tests, test)

    return new_suite
  end

  local mt = {}

  ---@param self suite The suite to add the test to.
  ---@param name string The name of the test.
  ---@return fun(...:identifier_table|modifier_table|fun()): suite
  function mt.__call(self, name)
    expect(1, name, "string")

    return function(...)
      return insert_test(name, ...)
    end
  end

  return setmetatable(new_suite, mt)
end

function suite.run_all_suites()
  for _, _suite in ipairs(suite.suites) do
    _suite.run(true)
  end

  print()
  logger.log_results(suite.suites)

  sleep(2)
  suite.cleanup()
end

--- Perform all cleanup operations.
function suite.cleanup()
  if methods.injected(_ENV) then
    methods.cleanup()
  end
  test_runner.cleanup()

  _ENV._cctest_env = nil
  suite.suites = {}
end

--- Load all test suites in a folder, runs recursively so you can have subfolders.
--- @param path string The path to the folder.
function suite.load_tests(path)
  if not fs.exists(path) then
    error("Path " .. path .. " does not exist.", 2)
  end

  local env = setmetatable({
    suite = suite
  }, {__index = _ENV})

  methods.inject(env)
  _ENV._cctest_env = env

  local function load_file(path)
    local file = fs.open(path, "r") --[[@as ReadHandle?]]
    if file then
      local data = file.readAll()
      file.close()

      if data then
        local func, err = load(data, "=" .. path, "t", env)
        if not func then
          error(err, 0)
        end

        local ok, err = pcall(func)
        if not ok then
          error(err, 0)
        end
      else
        error("Could not read file " .. path, 0)
      end
    else
      error("Could not open file " .. path, 0)
    end
  end

  -- Load and run all files in the folder.
  local files = fs.list(path)
  for _, file in ipairs(files) do
    local full_path = fs.combine(path, file)

    if fs.isDir(full_path) then
      suite.load_tests(full_path)
    else
      load_file(full_path)
    end
  end
end

return suite