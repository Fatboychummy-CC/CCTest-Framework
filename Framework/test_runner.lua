--- The main runner for the test suite.
--- This runs an individual test using coroutines, and stops the test on
--- specific coroutine return values.
--- Test status updates for `coroutine.resume`:
--- - `"cctest:fail_assertion", "ASSERTION_THAT_FAILED", "Error message"` Occurs when an assertion fails. The test should stop after this.
--- - `"cctest:fail_expectation", "EXPECTATION_THAT_FAILED", "Error message"` Occurs when an expectation fails. The test should continue after this.
--- - `"cctest:pass", "ASSERTION_OR_EXPECTATION_THAT_PASSED", nil` Occurs when an assertion or expectation has passed.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]

local MON_NAME = "CCTest Test Output"

if not peripheral.isPresent(MON_NAME) then
  ---@diagnostic disable-next-line: undefined-global -- This is a CraftOS-PC class.
  periphemu.create(MON_NAME, "monitor")
end
local mon = peripheral.wrap(MON_NAME)
local w, h = mon.getSize()
local mon_window = window.create(mon, 1, 2, w, h - 1)

--- Run a single test.
---@param test test_data The test to run.
---@param logger logger The logger to use.
---@return test_data test The test, with updated status. It is not required to grab the return value, as it modifies the table in-place.
local function run_test(test, logger)
  expect(1, test, "table")
  logger.new_test(test.name)
  mon.setCursorPos(1, 1)
  mon.setBackgroundColor(colors.purple)
  mon.setTextColor(colors.white)
  mon.clearLine()
  mon.write(test.name)
  mon.setBackgroundColor(colors.black)
  mon_window.setBackgroundColor(colors.black)
  mon_window.setTextColor(colors.white)
  mon_window.clear()
  mon_window.setCursorPos(1, 1)

  -- If the test is disabled, skip it.
  if test.status == "disabled" then
    logger.update_status "disabled"
    return test
  end

  -- If the test is new, run it.
  if test.status == "new" then
    local coro = test.coro
    local ok, last_event_filter, event_filter, test_assertion, message
    local resume_immediate = true -- This needs to be true so the coroutine can be initialized.

    test.status = "running"
    logger.update_status "running"
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

      -- Only handle terminate events, or events that match the last event filter (or cctest events)
      if event[1] == "terminate" or event[1] == last_event_filter or last_event_filter == nil then
        -- Resume the test's coroutine.

        local old = term.redirect(mon_window)
        mon_window.restoreCursor()
        ok, event_filter, test_assertion, message = coroutine.resume(coro, table.unpack(event, 1, event.n))
        term.redirect(old)

        if not ok then
          -- If the coroutine errored, the test errored. Report and exit.
          test.status = "error"
          test.error = event_filter

          logger.update_status "error"

          if logger.verbose then
            logger.log_stacktrace(debug.traceback(coro, event_filter))
          else
            logger.log_error(event_filter)
          end
          break
        elseif coroutine.status(coro) == "dead" then
          -- If the coroutine is dead, the test has ended.
          -- If no errors or failures were reported, the test passed.
          if test.status == "running" then
            test.status = "pass"
          end

          logger.update_status(test.status)
          break
        elseif event_filter:match("^cctest:") then
          -- If the response is a cctest response, handle it.
          local notification = event_filter:sub(8)
          if notification == "fail_assertion" then
            -- If an assertion failed, the test failed. Report and exit.
            test.status = "fail"
            table.insert(test.failures, message)
            logger.update_status "fail"
            logger.log_assertion(test_assertion, false, message)

            break
          elseif notification == "fail_expectation" then
            -- If an expectation failed, the test should continue, but is still marked as a failure.
            test.status = "fail"
            table.insert(test.failures, message)
            logger.update_status "fail"
            logger.log_expectation(test_assertion, false, message)

            -- We need to resume the coroutine immediately.
            resume_immediate = true
          elseif notification == "pass" then
            -- If an assertion or expectation passed, the test should continue.
            -- We need to resume the coroutine immediately.
            resume_immediate = true

            if test_assertion:match("^EXPECT_") then
              logger.log_expectation(test_assertion, true)
            else
              logger.log_assertion(test_assertion, true)
            end
          end
        else -- If the response is not a cctest response, update the event filter.
          last_event_filter = event_filter
        end
      end
    end
  end

  return test
end

return run_test
