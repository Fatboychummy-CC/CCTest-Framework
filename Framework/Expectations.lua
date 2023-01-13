--- Expect function input types. To replace `cc.expect` by returning a value instead of throwing an error.
---@param n integer Argument position.
---@param val any The input value.
---@param ... string The types to allow. Argument can be any of the input values.
---@return boolean satisfied If the expectation is satisfied.
---@return string error The error, if expectation fails.
local function expect(n, val, ...)
  local args = table.pack(...)
  local t = type(val)

  for i = 1, args.n do
    if t == args[i] then
      return true, ""
    end
  end

  return false,
      string.format(
        "Bad argument to test function #%d: Expected %s, got %s.",
        n,
        table.concat(
          args,
          " or "
        ),
        t
      )
end

local t_eq_error = "Tables are not equal."
--- Check if a table is equal to another table
---@param a table Table A
---@param b table Table B
---@param noflip boolean? Only check one direction if true.
---@return boolean equal If the table is equal.
---@return string string The error if the tables are not equal.
local function t_eq(a, b, noflip)
  if type(a) ~= "table" or type(b) ~= "table" then return false, t_eq_error end
  for k, v in pairs(a) do
    if type(v) == "table" then
      if not t_eq(v, b[k]) then return false, t_eq_error end
    elseif v ~= b[k] then
      return false, t_eq_error
    end
  end

  if not noflip then
    return t_eq(b, a, true)
  end

  return true, ""
end

---@class Expectations
local M = {}

--- Expect that an event should occur.
---@param f function The function to run, the event should occur sometime during this function running.
---@param timeout integer? If the function runs longer than this and no event occurs, fail.
---@param event string The event name to listen for.
---@param ... any The event arguments to test for.
---@return boolean satisfied If the expectation was satisfied.
---@return string? error If there was an error, return the error.
function M.EVENT(f, timeout, event, ...)
  local event_args = table.pack(...)
  if event_args[1] ~= event then
    table.insert(event_args, 1, event)
  end
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  ok, e = expect(2, event, "string")
  if not ok then return false, e end
  ok, e = expect(3, timeout, "number", "nil")
  if not ok then return false, e end

  local running = true
  local function run()
    ok, e = pcall(f)
    if not ok then error(e, 0) end

    sleep()
    running = false
  end

  local listen_ok, listen_err = false, ""
  local function listener()
    local tmr = os.startTimer(timeout or 0.25)
    while running do
      local ev = table.pack(os.pullEventRaw())
      if ev[1] == "timer" and ev[2] == tmr then
        listen_ok, listen_err = false, string.format("Timed out before receiving event '%s'.", event)
        return
      elseif ev[1] == event then
        for i = 1, event_args.n do
          local is_equal, err = M.EQ(event_args[i], ev[i])
          if not is_equal then
            listen_ok, listen_err = false, string.format("Event received, but argument %d is unexpected: %s", i, err)
            return
          end
        end
        listen_ok, listen_err = true, ""
        return
      end
    end
  end

  parallel.waitForAll(run, listener)

  return listen_ok, listen_err
end

--- Compare two values for equality.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If the values are equal.
---@return string error If the values are unequal.
function M.EQ(a, b)
  return a == b, string.format("Values %s and %s are unequal.", tostring(a), tostring(b))
end

--- Compare two values for inequality.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If the values are unequal.
---@return string error If the values are equal.
function M.UEQ(a, b)
  return a ~= b, string.format("Values %s and %s are equal.", tostring(a), tostring(b))
end

--- Check if value A is greater than value B.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If A > B.
---@return string error If A <= B.
function M.GT(a, b)
  return a > b, string.format("Value %s is not greater than %s.", tostring(a), tostring(b))
end

--- Check if value A is less than value B.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If A < B.
---@return string error If A >= B.
function M.LT(a, b)
  return a < b, string.format("Value %s is not less than %s.", tostring(a), tostring(b))
end

--- Check if value A is greater than or equal to value B.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If A >= B.
---@return string error If A < B.
function M.GTE(a, b)
  return a >= b, string.format("Value %s is not greater than or equal to %s.", tostring(a), tostring(b))
end

--- Check if value A is less than or equal to value B.
---@param a any Value A.
---@param b any Value B.
---@return boolean satisfied If A <= B.
---@return string error If A > B.
function M.LTE(a, b)
  return a <= b, string.format("Value %s is not less than or equal to %s.", tostring(a), tostring(b))
end

--- Check if a table is equal to another table, comparing recursively.
---@param a table Table A.
---@param b table Table B.
---@return boolean satisfied If both tables have equal keys and values.
---@return string error If the tables are not equal.
function M.DEEP_TABLE_EQ(a, b)
  local mt = getmetatable(a) ---@type table?
  if mt and mt.__pairs then
    local ok = pcall(pairs, a)
    if not ok then
      return false, "Cannot step through table input a: __pairs is overridden and generates an error when called."
    end
  end
  mt = nil
  mt = getmetatable(b)
  if mt and mt.__pairs then
    local ok = pcall(pairs, b)
    if not ok then
      return false, "Cannot step through table input b: __pairs is overridden and generates an error when called."
    end
  end
  local ok, e = expect(1, a, "table")
  if not ok then return false, e end
  local ok2, e2 = expect(2, b, "table")
  if not ok2 then return false, e2 end
  return t_eq(a, b)
end

--- Compare that two float values are "close enough" to be equal, since floats don't like to play nice with equality checks sometimes.
---@param a number Number A.
---@param b number Number B.
---@param range number Maximum offset between the two values allowed.
---@return boolean satisfied If the floats are "close enough".
---@return string error If the floats were not close enough.
function M.FLOAT_EQ(a, b, range)
  local ok, e = expect(3, range, "number", "nil")
  if not ok then return false, e end
  range = range or 0.000000000001
  return a >= b - range and a <= b + range,
      string.format("Value %s is not within %f of %s", tostring(a), range, tostring(b))
end

--- Expect that a value is of type 't'.
---@param a any The value to test.
---@param t string The type to test for.
---@return boolean satisfied If the type of the value was the type expected.
---@return string error If the type of the value was not the type expected.
function M.TYPE(a, t)
  local ok, e = expect(2, t, "string")
  if not ok then return false, e end
  return type(a) == t, string.format("Value %s is not of type %s.", tostring(a), t)
end

--- Expect that a value is one of the given types.
---@param a any The value to test.
---@param ... string The types to test for.
---@return boolean satisfied If the type of the value was expected.
---@return string error If the type of the value was not expected.
function M.TYPES(a, ...)
  local types = table.pack(...)
  for i = 1, types.n do
    local ok, e = expect(i + 1, types[i], "string")
    if not ok then return false, e end

    if type(a) ~= types[i] then
      return false, string.format("Value %s is not of type %s.", tostring(a), table.concat(types, " or "))
    end
  end

  return true, ""
end

--- Expect a value to be true.
---@param a boolean The value.
---@return boolean satisfied If the value is true.
---@return string error If the value is not true.
function M.TRUE(a)
  return a == true, string.format("Value %s is not 'true'.", tostring(a))
end

--- Expect a value to be false.
---@param a boolean The value.
---@return boolean satisfied If the value is false.
---@return string error If the value is not false.
function M.FALSE(a)
  return a == false, string.format("Value %s is not 'false'.", tostring(a))
end

--- Expect a value to be truthy.
---@param a any The value.
---@return boolean satisfied If the value is truthy.
---@return string error If the value is not truthy.
function M.TRUTHY(a)
  return not not a, string.format("Value %s is not truthy.", tostring(a))
end

--- Expect a value to be falsey.
---@param a false? The value.
---@return boolean satisfied If the value is falsey.
---@return string error If the value is not falsey.
function M.FALSEY(a)
  return not a, string.format("Value %s is not falsey.", tostring(a))
end

--- Expect that a function will throw any error with the given arguments.
---@param f function The function to test.
---@param ... any The arguments to give to the function.
---@return boolean satisfied If the function threw any error.
---@return string error If the function did not throw an error.
function M.THROW_ANY_ERROR(f, ...)
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  local ok2 = pcall(f, ...)
  return not ok2, "Function did not throw an error."
end

--- Expect that a function will throw an error that follows a specific pattern, given specific arguments.
---@param f function The function to test.
---@param m string The match pattern to use.
---@param ... any The arguments to give to the function.
---@return boolean satisfied If the function threw an error that matched the given pattern.
---@return string error If the function did not throw an error, or it did not match the pattern.
function M.THROW_MATCHED_ERROR(f, m, ...)
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  local ok2, e2 = expect(2, m, "string")
  if not ok2 then return false, e2 end

  local ok3, err = pcall(f, ...)
  if ok3 then return false, "Function did not throw an error." end

  local match = string.match(err, m)
  return match and true or false, string.format("Error '%s' does not match pattern '%s'.", err, m)
end

--- Expect that a function will NOT throw any error, given specific arguments.
---@param f function The function to test.
---@param ... any The arguments to give to the function.
---@return boolean satisfied If the function did not throw an error.
---@return string error If the function threw an error.
function M.NO_THROW(f, ...)
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  local ok, err = pcall(f, ...)
  return ok, string.format("Function threw error: %s", err)
end

return M
