--- Allows for the creation of mock objects, which can have methods return specific values.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]

---@class mock_objects
local mock_objects = {}

---@alias return_chain_types
---| '"once"' # The return value should be returned once.
---| '"n"' # The return value should be returned n times.
---| '"always"' # The return value should be returned always.

---@class cctest_return_value
---@field type return_chain_types The type of return value.
---@field value any[] The return value(s).
---@field n number? The number of times the return value should be returned, if the type is `"n"`.
---@field private __cctest_name string The name of the function.

---@class cctest_call
---@field args any[] The arguments the function should be called with.
---@field times number The number of times the function should be called.
---@field actual number The number of times the function has been called with the given arguments.
---@field parent mock_function The parent function.
---@field private __cctest_name string The name of the function.

--- Get the next return value for a mocked function.
---@param func mock_function The mocked function.
---@return any next The next return value.
function mock_objects.get_next_return_value(func)
  expect(1, func, "table")

  local return_chain = func.return_chain

  -- Case 1: No return value
  if #return_chain == 0 then
    return -- No return values, return nil.
  end

  local return_value = return_chain[1]

  -- Case 2: Return once
  if return_value.type == "once" then
    table.remove(return_chain, 1) -- Remove the return value from the chain.
    return table.unpack(return_value.value) -- Return the value.
  end

  -- Case 3: Return always
  if return_value.type == "n" then
    return_value.n = return_value.n - 1 -- Decrement the number of times the value should be returned.
    if return_value.n <= 0 then
      table.remove(return_chain, 1) -- Remove the return value from the chain.
    end
    return table.unpack(return_value.value) -- Return the value.
  end

  -- Case 4: Return always
  if return_value.type == "always" then
    return table.unpack(return_value.value) -- Return the value.
  end

  error(("Mock object '%s' has an invalid return type '%s' in its return chain."):format(func.__cctest_name, return_value.type), 0)
end

--- Create a new mock object.
---@param name string A descriptive name for the mock object (used in error messages).
---@param properties table? The default properties of the mock object.
---@return mock_object mock_object The mock object.
function mock_objects.new(name, properties)
  expect(1, properties, "table", "nil")

  properties = properties or {}
  properties.__cctest_name = name

    ---@class mock_object
  local obj = {}
  for k, v in pairs(properties) do
    obj[k] = v
  end

  --- Add a mocked method to the object.
  ---@param name string The name of the method.
  ---@return mock_function mock_function The mock function.
  function obj.MOCK_METHOD(name)
    expect(1, name, "string")

    ---@class mock_function
    ---@field failed boolean Whether the function has failed.
    ---@field return_chain cctest_return_value[] The return chain of the function.
    ---@field call_chain cctest_call[] The call chain of the function.
    ---@field __cctest_name string The name of the function.
    local func = {
      return_chain = {},
      call_chain = {},
      failed = false,
      __cctest_name = obj.__cctest_name .. "." .. name,
    }

    --- Set the next return value of the function.
    ---@param ... any The return value(s) of the function.
    ---@return mock_function mock_function The mock function.
    function func.RETURN_ONCE(...)
      local t = {
        type = "once",
        value = table.pack(...),
      }
      table.insert(func.return_chain, t)

      return func
    end

    --- Set the next n return values of the function to the given value.
    ---@param n number The number of times to return the value.
    ---@param ... any The return value(s) of the function.
    ---@return mock_function mock_function The mock function.
    function func.RETURN_N(n, ...)
      expect(1, n, "number")
      local t = {
        type = "n",
        value = table.pack(...),
        n = n,
      }
      table.insert(func.return_chain, t)

      return func
    end

    --- Set the function to always return a certain value.
    ---@param ... any The return value(s) of the function.
    ---@return mock_function mock_function The mock function.
    function func.RETURN_ALWAYS(...)
      local t = {
        type = "always",
        value = table.pack(...),
      }
      table.insert(func.return_chain, t)

      return func
    end

    --- Expect that the method is called the given amount of times with the
    --- given arguments.
    ---@param times number The number of times the method should be called.
    ---@param ... any The arguments the method should be called with.
    ---@return mock_function mock_function The mock function.
    function func.EXPECT_CALL(times, ...)
      expect(1, times, "number")

      local t = {
        type = "expect",
        times = times,
        actual = 0,
        args = table.pack(...),
        parent = func,
      }

      table.insert(func.call_chain, t)

      return func
    end

    obj[name] = func
    return setmetatable(func, {
      __call = function(self, ...)
        return coroutine.yield("ccmock:call_method", self, table.pack(...))
      end
    })
  end

  return setmetatable(obj, {
    __index = function(self, idx)
      return function(...)
        coroutine.yield("cctest:fail_expectation", "MOCKED_OBJECT", ("Mock object '%s' has no method '%s'."):format(obj.__cctest_name, idx))
      end
    end
  })
end

return mock_objects