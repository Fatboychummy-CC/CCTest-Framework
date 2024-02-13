--- The main runner for the test suite.
--- This runs an individual test using coroutines, and stops the test on
--- specific coroutine return values.
--- Test status updates for `coroutine.resume`:
--- - `"cctest:fail_assertion", "ASSERTION_THAT_FAILED", "Error message"` Occurs when an assertion fails. The test should stop after this.
--- - `"cctest:fail_expectation", "EXPECTATION_THAT_FAILED", "Error message"` Occurs when an expectation fails. The test should continue after this.
--- - `"cctest:pass", "ASSERTION_OR_EXPECTATION_THAT_PASSED", nil` Occurs when an assertion or expectation has passed.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]
local mock = require "Framework.mock"

local MON_NAME = "CCTest Test Output"

local periphemu = periphemu
local no_periphemu = false

if not periphemu then
  no_periphemu = true
  periphemu = {
    create = function()
      local mon = peripheral.find("monitor")
      if not mon then
        error("No monitor found.", 0)
      end
      MON_NAME = peripheral.getName(mon)
      print("Found monitor:", MON_NAME)
    end,
    remove = function(name)
      expect(1, name, "string")
      peripheral.call(MON_NAME, "setBackgroundColor", colors.black)
      peripheral.call(MON_NAME, "setTextColor", colors.white)
      peripheral.call(MON_NAME, "clear")
    end
  }
end

if not peripheral.isPresent(MON_NAME) then
  periphemu.create(MON_NAME, "monitor")
end

local mon = peripheral.wrap(MON_NAME) --[[@as Monitor The monitor is guaranteed to exist here.]]

if not no_periphemu then
  mon.setSize(51, 20) -- Set the monitor size to one taller than the default term size, to account for our header.
end
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

  ---@type table<mock_function, true>
  local tracked_mock_methods = {}

  -- If the test is disabled, skip it.
  if test.status == "disabled" then
    logger.update_status "disabled"
    return test
  end

  local tentative_pass = false

  -- If the test is new, run it.
  if test.status == "new" then
    local coro = test.coro
    local ok, last_event_filter, event_filter, test_assertion, message
    local resume_immediate = true -- This needs to be true so the coroutine can be initialized.

    test.status = "running"
    logger.update_status "running"
    local next_event
    while true do
      local event

      -- If we need to resume immediately (i.e: after a pass or expectation
      -- failure), do so.
      if resume_immediate then
        event = next_event or { n = 0 }
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
            test.status = "post"
            tentative_pass = true
          end

          logger.update_status(test.status)
          break
        elseif event_filter == nil then
          -- If no event filter was passed (i.e: called `os.pullEvent()` with no
          -- arguments), set the event filter to anything.
          -- This has the added benefit of not causing `attempt to index nil
          -- value` errors in the next few elseifs.
          -- ...
          -- Yes, I forgot to add this in originally, how could you tell?
          last_event_filter = nil
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
          elseif notification == "force_pass" then
            -- On a force pass, the test should just be marked as a pass.
            test.status = "pass"
            logger.update_status "pass"
            logger.log_expectation("PASS", true)
            resume_immediate = true
          end
        elseif event_filter:match("^ccmock:") then
          -- If the response is a ccmock response, handle it.
          local notification = event_filter:sub(8)
          ---@cast test_assertion mock_function
          if notification == "track_method" then
            -- If the user pushed info to a mock method (i.e: 
            -- `mock_method.RETURNS_ONCE(something)), save it.
            -- Post-process task needed: Check all mock methods to see if they
            -- were changed during this test. If they were, check if they were
            -- called according to the user's expectations.
            tracked_mock_methods[test_assertion] = true
          elseif notification == "call_method" then
            -- test_assertion stores the mock method, and message stores the
            -- arguments.
            tracked_mock_methods[test_assertion] = true

            ---@FIXME implement proper logic to check if the right arguments were passed to this.
            table.remove(test_assertion.call_chain, 1)

            -- Store the return values and note to return immediately.
            next_event = table.pack(mock.get_next_return_value(test_assertion))
            resume_immediate = true
          end
        else -- If the response is not a cctest response, update the event filter.
          last_event_filter = event_filter
        end
      end
    end

    if test.modifiers.POST_DELAY then
      sleep(test.modifiers.POST_DELAY)
    end
  end

  -- Post process tasks:
  -- 1. Check all mock methods to see if they were changed during this test.
  --  a) If they were, check if they were called according to the user's
  --     expectations.
  --  b) If they weren't, log failures.

  -- 1
  for mock_method in pairs(tracked_mock_methods) do
    -- 1.a.1: Check if anything remains in the mock method's call stack.
    if #mock_method.call_chain > 0 then
      -- If anything remains in the call stack, then the mock method was not
      -- called enough times, as it should be empty by the end of the test.

      test.status = "fail"
      logger.update_status "fail"
      tentative_pass = false

      -- 1.a.2: For each expected call in the call stack, log a failure.
      for _, expected_call in ipairs(mock_method.call_chain) do
        logger.log_expectation(
          "EXPECT_CALL", -- hard-coding currently, no other mock call exists.
          false,
          string.format(
            "Expected %s to be called with %d argument(s), but it was not called.",
            mock_method.__cctest_name,
            expected_call.args.n
          )
        )
        -- and mark it as failed
        mock_method.failed = true
      end

      mock_method.failed = true
    end

    if not mock_method.failed then
      -- Log a pass.
      logger.log_expectation(
        "EXPECT_CALL", -- hard-coding currently, no other mock call exists.
        true
      )
    end
  end

  if tentative_pass then
    test.status = "pass"
    logger.update_status "pass"
  end

  return test
end

return {
  run_test = run_test,

  --- Cleanup the test runner's monitor
  cleanup = function()
    periphemu.remove(MON_NAME)
  end,

  --- Setup the test runner's monitor
  setup = function()
    if not peripheral.isPresent(MON_NAME) then
      periphemu.create(MON_NAME, "monitor")
    end
    mon = peripheral.wrap(MON_NAME) --[[@as Monitor]]
    if not no_periphemu then
      mon.setSize(51, 20) -- Set the monitor size to one taller than the default term size, to account for our header.
    end
    w, h = mon.getSize()
    mon_window = window.create(mon, 1, 2, w, h - 1)
  end
}
