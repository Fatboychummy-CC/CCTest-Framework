--- This file contains functions that can be used in tests.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]

---@class test_methods Functions to be used in tests.
local methods = {
  funcs = {}
}

--- Wrap a function to be used as both an expectation and an assertion.
---@param name string The name of the function.
---@param func function The function to wrap. 
local function generate_for_both(name, func)
  methods.funcs["ASSERT_" .. name] = func("cctest:fail_assertion", "ASSERT_" .. name)
  methods.funcs["EXPECT_" .. name] = func("cctest:fail_expectation", "EXPECT_" .. name)
end

--- Get the caller of the function that called this function.
---@return string caller The caller of the function that called this function.
local function get_caller()
  local info = debug.getinfo(3, "Sl")
  return ("%s:%d"):format(info.short_src, info.currentline)
end

generate_for_both("TRUE", function(fail_event, name)
  return function(value)
    if value ~= true then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not true."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("FALSE", function(fail_event, name)
  return function(value)
    if value ~= false then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not false."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("NIL", function(fail_event, name)
  return function(value)
    if value ~= nil then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not nil."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("NOT_NIL", function(fail_event, name)
  return function(value)
    if value == nil then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is nil."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("TRUTHY", function(fail_event, name)
  return function(value)
    if not value then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not truthy."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("FALSY", function(fail_event, name)
  return function(value)
    if value then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not falsy."):format(tostring(value)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

-- Alias for different spellings.
methods.funcs.ASSERT_FALSEY = methods.funcs.EXPECT_FALSY
methods.funcs.EXPECT_FALSEY = methods.funcs.EXPECT_FALSY

generate_for_both("EQ", function(fail_event, name)
  return function(expected, actual)
    if expected ~= actual then
      coroutine.yield(fail_event, get_caller(), name, ("Values %s and %s are not equal."):format(tostring(expected), tostring(actual)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("NEQ", function(fail_event, name)
  return function(expected, actual)
    if expected == actual then
      coroutine.yield(fail_event, get_caller(), name, ("Values %s and %s are equal."):format(tostring(expected), tostring(actual)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("THROWS", function(fail_event, name)
  return function(func, ...)
    expect(1, func, "function")

    local success, err = pcall(func, ...)
    if success then
      coroutine.yield(fail_event, get_caller(), name, "Function did not throw an error.")
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("THROWS_MATCH", function(fail_event, name)
  return function(func, pattern, ...)
    expect(1, func, "function")
    expect(2, pattern, "string")

    local success, err = pcall(func, ...)
    if success then
      coroutine.yield(fail_event, get_caller(), name, "Function did not throw an error.")
      return
    elseif not err:match(pattern) then
      coroutine.yield(fail_event, get_caller(), name, ("Error %s did not match pattern %s."):format(err, pattern))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("NO_THROW", function(fail_event, name)
  return function(func, ...)
    expect(1, func, "function")

    local success, err = pcall(func, ...)
    if not success then
      coroutine.yield(fail_event, get_caller(), name, ("Function threw an error: %s."):format(err))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("TYPE", function(fail_event, name)
  return function(actual, ...)
    actual = type(actual)
    local expected = table.pack(...)
    for i = 1, expected.n do
      if type(expected[i]) ~= "string" then
        expect(i + 1, expected[i], "string")
      end
      if actual == expected[i] then
        coroutine.yield("cctest:pass", get_caller(), name)
        return
      end
    end

    coroutine.yield(fail_event, get_caller(), name, ("Value %s is not of type %s."):format(tostring(actual), table.concat(expected, ", ")))
  end
end)

generate_for_both("GE", function(fail_event, name)
  return function(a, b)
    if a < b then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not greater than or equal to %s."):format(tostring(a), tostring(b)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("GT", function(fail_event, name)
  return function(a, b)
    if a <= b then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not greater than %s."):format(tostring(a), tostring(b)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("LE", function(fail_event, name)
  return function(a, b)
    if a > b then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not less than or equal to %s."):format(tostring(a), tostring(b)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("LT", function(fail_event, name)
  return function(a, b)
    if a >= b then
      coroutine.yield(fail_event, get_caller(), name, ("Value %s is not less than %s."):format(tostring(a), tostring(b)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("FLOAT_EQ", function(fail_event, name)
  return function(a, b, epsilon)
    expect(1, a, "number")
    expect(2, b, "number")
    expect(3, epsilon, "number", "nil")
    epsilon = epsilon or 0.00001

    if math.abs(a - b) > epsilon then
      coroutine.yield(fail_event, get_caller(), name, ("Values %s and %s are not equal within epsilon %s."):format(tostring(a), tostring(b), tostring(epsilon)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("FLOAT_NEQ", function(fail_event, name)
  return function(a, b, epsilon)
    expect(1, a, "number")
    expect(2, b, "number")
    expect(3, epsilon, "number", "nil")
    epsilon = epsilon or 0.00001

    if math.abs(a - b) <= epsilon then
      coroutine.yield(fail_event, get_caller(), name, ("Values %s and %s are equal within epsilon %s."):format(tostring(a), tostring(b), tostring(epsilon)))
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("MATCH", function(fail_event, name)
  return function(actual, ...)
    expect(1, actual, "string")

    local expected = table.pack(...)

    for i = 1, expected.n do
      if type(expected[i]) ~= "string" then
        expect(i + 1, expected[i], "string")
      end
      if actual:match(expected[i]) then
        coroutine.yield("cctest:pass", get_caller(), name)
        return
      end
    end

    coroutine.yield(fail_event, get_caller(), name, ("Value %s does not match any of the patterns: %s."):format(tostring(actual), table.concat(expected, ", ")))
  end
end)

generate_for_both("DEEP_EQ", function(fail_event, name)
  return function(a, b)
    expect(1, a, "table")
    expect(2, b, "table")

    local function eq_one_way(_a, _b)
      if type(_a) ~= type(_b) then
        return false
      end

      if type(_a) == "table" then
        for k, v in pairs(_a) do
          if not eq_one_way(v, _b[k]) then
            return false
          end
        end
        return true
      else
        return _a == _b
      end
    end

    if not eq_one_way(a, b) or not eq_one_way(b, a) then
      coroutine.yield(fail_event, get_caller(), name, "Tables are not deeply equal.")
      return
    end
    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

generate_for_both("TIMEOUT", function(fail_event, name)
  return function(func, time, ...)
    expect(1, func, "function")
    expect(2, time, "number")

    local timer = os.startTimer(time)
    local args = table.pack(...)
    local start_time = os.epoch "utc"

    local killed = false

    parallel.waitForAny(
      function()
        func(table.unpack(args, 1, args.n))
      end,
      function()
        while true do
          local event = {os.pullEvent()}
          if event[1] == "timer" and event[2] == timer then
            killed = true
            return
          end
        end
      end
    )

    local end_time = os.epoch "utc"

    if killed then
      coroutine.yield(fail_event, get_caller(), name, ("Function did not complete within %d seconds."):format(time))
      return
    end


    if end_time - start_time > time * 1000 then
      coroutine.yield(fail_event, get_caller(), name, ("Function took %d seconds to complete, but should have taken less than %d seconds."):format((end_time - start_time) / 1000, time))
      return
    end

    coroutine.yield("cctest:pass", get_caller(), name)
  end
end)

methods.funcs.PASS = function()
  coroutine.yield("cctest:force_pass", get_caller())
end

methods.funcs.FAIL = function(reason)
  coroutine.yield("cctest:fail_expectation", "FAIL", get_caller(), reason or "Manual failure.")
end

methods.funcs.END = function(reason)
  coroutine.yield("cctest:fail_assertion", "END", get_caller(), reason or "Manual failure.")
end

--- Inject the methods into the global environment.
---@param env table? The environment to inject the methods into. Defaults to _ENV.
function methods.inject(env)
  env = env or _ENV
  for name, func in pairs(methods.funcs) do
    env[name] = func
  end

  env._cctest_injected = true
end

--- Check if cctest is injected in an environment.
---@param env table? The environment to check. Defaults to _ENV.
---@return boolean injected Whether cctest is injected.
function methods.injected(env)
  env = env or _ENV
  return env._cctest_injected == true
end

--- Remove the methods from the global environment.
function methods.cleanup()
  for name, func in pairs(methods.funcs) do
    _ENV[name] = nil
  end
end

return methods