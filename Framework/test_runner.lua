--- The main runner for the test suite.
--- This runs an individual test using coroutines, and stops the test on
--- specific coroutine return values.
--- Test status updates for `coroutine.resume`:
--- - `"cctest:fail_assertion", "ASSERTION_THAT_FAILED", "Error message"` Occurs when an assertion fails. The test should stop after this.
--- - `"cctest:fail_expectation", "EXPECTATION_THAT_FAILED", "Error message"` Occurs when an expectation fails. The test should continue after this.
--- - `"cctest:pass", "ASSERTION_OR_EXPECTATION_THAT_PASSED", nil` Occurs when an assertion or expectation has passed.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]

--- Run a single test.
---@param test test_data The test to run.
---@return test_data test The test, with updated status. It is not required to grab the return value, as it modifies the table in-place.
local function run_test(test, logger)
  expect(1, test, "table")

  -- If the test is disabled, skip it.
  if test.status == "disabled" then
    return test
  end

  -- If the test is new, run it.
  if test.status == "new" then
    local coro = test.coro
    local ok, event_filter, test_assertion, message
    local resume_immediate = false

    test.status = "running"
    while true do
      local event

      -- If we need to resume immediately (i.e: after a pass or expectation
      -- failure), do so.
      if resume_immediate then
        event = { n = 0 }
        resume_immediate = false
      else
        event = table.pack(os.pullEventRaw())
      end

      -- Resume the test's coroutine.
      ok, event_filter, test_assertion, message = coroutine.resume(coro, table.unpack(event, 1, event.n))


      if not ok then
        -- If the coroutine errored, the test errored. Report and exit.
        test.status = "error"
        test.error = event_filter
        break
      elseif coroutine.status(coro) == "dead" then
        -- If the coroutine is dead, the test has ended.
        -- If no errors or failures were reported, the test passed.
        if test.status == "running" then
          test.status = "pass"
        end
        break
      elseif event_filter:match("^cctest:") then
        if event_filter == "cctest:fail_assertion" then
          -- If an assertion failed, the test failed. Report and exit.
          test.status = "fail"
          table.insert(test.failures, message)
          break
        elseif event_filter == "cctest:fail_expectation" then
          -- If an expectation failed, the test should continue, but is still marked as a failure.
          test.status = "fail"
          table.insert(test.failures, message)

          -- We need to resume the coroutine immediately.
          resume_immediate = true
        elseif event_filter == "cctest:pass" then
          -- If an assertion or expectation passed, the test should continue.
          -- We need to resume the coroutine immediately.
          resume_immediate = true
        end
      end
    end
  end

  return test
end

return run_test
