--- A logging library purpose-built for the test framework.

local expect = require "cc.expect".expect --[[@as fun(a: number, b: any, ...: string)]]

---@class logger
---@field current_test_name string? The name of the current test.
---@field current_status test_status? The status of the current test.
---@field y number? The current y position of the logger.
---@field verbose boolean Whether to print verbose output.
local logger = {
  current_test_name = nil,
  current_status = nil,
  y = 0,
}

local SUITE_NAME_COLOR = 'b' -- Blue
local TEST_NAME_COLOR = 'a'  -- Purple
local EXPECT_COLOR = '4'     -- Yellow
local ASSERT_COLOR = '1'     -- Orange
local ERROR_COLOR = 'e'      -- Red
local DEFAULT_BG_COLOR = 'f' -- Black
local WHITE = '0'            -- White
local PASSED_COLOR = '5'     -- Lime
local FAILED_COLOR = 'e'     -- Orange


--- Format the status into a valid blit string.
---@param status test_status The status to format.
---@return string text The formatted status, as text.
---@return string text_color The formatted status, as blit text color.
---@return string bg_color The formatted status, as blit background color.
local function format_status(status)
  expect(1, status, "string")

  if status == "pass" then
    return "[PASS ]: ", "055555000", "fffffffff"
  elseif status == "fail" then
    return "[ FAIL]: ", "0eeeee000", "fffffffff"
  elseif status == "error" then
    return "[ERROR]: ", "000000000", "feeeeefff"
  elseif status == "disabled" then
    return "[DSBLD]: ", "0ccccc000", "fffffffff"
  elseif status == "new" then
    return "[ NEW ]: ", "099999000", "fffffffff"
  elseif status == "running" then
    return "[ RUN ]: ", "000000000", "fffffffff"
  end

  return "[?????]: ", "044444000", "fffffffff"
end

--- Combine values into valid blit strings, in the format of
--- `a1 .. a2 .. a3, b1 .. b2 .. b3, c1 .. c2 .. c3`.
--- The input values are expected to be in the format of
--- `a1, b1, c1, a2, b2, c2, a3, b3, c3`.
---@vararg string|table The values to combine. Tables will be pulled apart to allow for multiple values if calling functions.
---@return string text The combined text values.
---@return string text_color The combined text color values.
---@return string bg_color The combined background color values.
local function combine_blit(...)
  local text = ""
  local text_color = ""
  local bg_color = ""

  local args = table.pack(...)

  local fixed_args = {}

  -- Rip subtables out and insert them as if they were arguments.
  for i = 1, args.n do
    local arg = args[i]
    if type(arg) == "table" then
      for j = 1, #arg do
        table.insert(fixed_args, arg[j])
      end
    else
      table.insert(fixed_args, arg)
    end
  end

  for i = 1, #fixed_args, 3 do
    local s1, s2, s3 = fixed_args[i], fixed_args[i + 1], fixed_args[i + 2]
    expect(i, s1, "string")
    expect(i + 1, s2, "string")
    expect(i + 2, s3, "string")

    if #s1 ~= #s2 or #s1 ~= #s3 then
      error(("Bad arguments %d, %d, %d: Must be same length (got %d, %d, %d)"):format(i, i + 1, i + 2, #s1, #s2, #s3), 2)
    end

    text = text .. s1
    text_color = text_color .. s2
    bg_color = bg_color .. s3
  end

  return text, text_color, bg_color
end

--- Give an entire message a blit background and text color.
---@param message string The message to blit.
---@param text_color string The text color to use.
---@param bg_color string The background color to use.
---@return string text The blit text (the same as inputted).
---@return string text_color The blit text color.
---@return string bg_color The blit background color.
local function bmsg(message, text_color, bg_color)
  expect(1, message, "string")
  expect(2, text_color, "string")
  expect(3, bg_color, "string")

  text_color = text_color:rep(#message)
  bg_color = bg_color:rep(#message)

  return message, text_color, bg_color
end

--- Display information about the new suite.
--- @param name string The name of the suite.
--- @param test_count number The number of tests in the suite.
function logger.new_suite(name, test_count)
  expect(1, name, "string")
  expect(2, test_count, "number")

  print()

  term.blit(
    combine_blit(
      { bmsg("Running suite ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(name, SUITE_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" with ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(tostring(test_count), SUITE_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" tests.", WHITE, DEFAULT_BG_COLOR) }
    )
  )

  print()
end

--- Shift logger focus to a new test.
---@param name string The name of the test.
function logger.new_test(name)
  expect(1, name, "string")

  logger.current_test_name = name
  logger.current_status = "new"

  -- print once if not verbose, otherwise twice.
  print()
  if logger.verbose then
    print()
  end

  local _; _, logger.y = term.getCursorPos()
  local text, text_color, bg_color = format_status(logger.current_status)
  term.blit(
    combine_blit(
      text, text_color, bg_color,
      bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR)
    )
  )
end

--- Update the status of the current test.
---@param status test_status The new status of the test.
function logger.update_status(status)
  expect(1, status, "string")

  if logger.current_status == status then
    -- Do nothing if the status hasn't changed.
    return
  end

  logger.current_status = status

  local text, text_color, bg_color = format_status(logger.current_status)

  if logger.verbose then
    -- If verbose, print a new line so each status is on a new line.
    print()
  else
    -- Otherwise, clear the current line and reprint the status.
    term.setCursorPos(1, logger.y)
    term.clearLine()
  end

  term.blit(
    combine_blit(
      text, text_color, bg_color,
      bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR)
    )
  )
end

--- Log an expectation.
---@param expectation string The expectation to log.
---@param passed boolean Whether the expectation passed.
---@param message string? The message to log. Nil if passed.
function logger.log_expectation(expectation, passed, message)
  expect(1, expectation, "string")
  expect(2, passed, "boolean")
  expect(3, message, "string", "nil")

  if not passed then
    logger.current_status = "fail"
  end

  local text, text_color, bg_color = format_status(logger.current_status)

  if logger.verbose then
    -- If verbose, print a new line so each status is on a new line.
    print()
  else
    -- Otherwise, clear the current line and reprint the status.
    term.setCursorPos(1, logger.y)
    term.clearLine()
  end

  term.blit(
    combine_blit(
      text, text_color, bg_color,
      { bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" | ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(expectation, EXPECT_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" : ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(message or "Passed.", passed and PASSED_COLOR or FAILED_COLOR, DEFAULT_BG_COLOR) }
    )
  )

  if not passed and not logger.verbose then
    -- If the expectation failed, print a new line to ensure it doesn't get overwritten.
    print()
    local _; _, logger.y = term.getCursorPos()
  end
end

--- Log an assertion.
---@param assertion string The assertion to log.
---@param passed boolean Whether the assertion passed.
---@param message string? The message to log. Nil if passed.
function logger.log_assertion(assertion, passed, message)
  expect(1, assertion, "string")
  expect(2, passed, "boolean")
  expect(3, message, "string", "nil")

  if not passed then
    logger.current_status = "fail"
  end

  local text, text_color, bg_color = format_status(logger.current_status)

  if logger.verbose then
    -- If verbose, print a new line so each status is on a new line.
    print()
  else
    -- Otherwise, clear the current line and reprint the status.
    term.setCursorPos(1, logger.y)
    term.clearLine()
  end

  term.blit(
    combine_blit(
      text, text_color, bg_color,
      { bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" | ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(assertion, ASSERT_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" : ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(message or "Passed.", passed and PASSED_COLOR or FAILED_COLOR, DEFAULT_BG_COLOR) }
    )
  )

  if not passed and not logger.verbose then
    -- If the assertion failed, print a new line to ensure it doesn't get overwritten.
    print()
    local _; _, logger.y = term.getCursorPos()
  end
end

--- Log an error.
---@param error string The error to log.
function logger.log_error(error)
  expect(1, error, "string")

  -- Always print errors on new lines.
  print()

  term.blit(
    combine_blit(
      { bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" | ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg("ERROR", ERROR_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" : ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(error, ERROR_COLOR, DEFAULT_BG_COLOR) }
    )
  )

  -- And print a new line to ensure it doesn't get overwritten
  print()
end

--- Log a failure.
---@param failure string The failure to log.
function logger.log_failure(failure)
  expect(1, failure, "string")

  -- Always print failures on new lines.
  print()

  term.blit(
    combine_blit(
      { bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" | ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg("FAIL", FAILED_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" : ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(failure, FAILED_COLOR, DEFAULT_BG_COLOR) }
    )
  )

  -- And print a new line to ensure it doesn't get overwritten
  print()
end

function logger.log_stacktrace(stacktrace)
  expect(1, stacktrace, "string")

  -- Always print stacktraces on new lines.
  print()

  term.blit(
    combine_blit(
      { bmsg(logger.current_test_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" | ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg("STACKTRACE", ERROR_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(":", WHITE, DEFAULT_BG_COLOR) }
    )
  )

  print()
  printError(stacktrace)

  -- and always print a new line to ensure it doesn't get overwritten
  print()
  local _; _, logger.y = term.getCursorPos()

  -- And print a new line to ensure it doesn't get overwritten
  print()
end

--- Log the results of the given suites
---@param suites suite[] The suites to log.
function logger.log_results(suites)
  -- First count the number of tests and failures for each suite.
  ---@type table<suite, {tests: number, failures: number, fail_names: string[]}>
  local data = {}
  local suite_count = 0

  for _, suite in ipairs(suites) do
    suite_count = suite_count + 1
    data[suite] = {
      tests = 0,
      failures = 0,
      fail_names = {},
    }

    for _, test in ipairs(suite.tests) do
      data[suite].tests = data[suite].tests + 1
      if test.status == "fail" or test.status == "error" then
        data[suite].failures = data[suite].failures + 1
        table.insert(data[suite].fail_names, test.name)
      end
    end
  end

  -- Then print the results.
  print()

  -- Start with the count of suites
  term.blit(
    combine_blit(
      { bmsg("Ran ", WHITE, DEFAULT_BG_COLOR) },
      { bmsg(tostring(suite_count), SUITE_NAME_COLOR, DEFAULT_BG_COLOR) },
      { bmsg(" suite(s).", WHITE, DEFAULT_BG_COLOR) }
    )
  )

  -- Then print the results for each suite THAT HAD FAILURES.
  for suite, suite_data in pairs(data) do
    if suite_data.failures > 0 then
      print()
      term.blit(
        combine_blit(
          { bmsg("Suite ", WHITE, DEFAULT_BG_COLOR) },
          { bmsg(suite.name, SUITE_NAME_COLOR, DEFAULT_BG_COLOR) },
          { bmsg(" had ", WHITE, DEFAULT_BG_COLOR) },
          { bmsg(tostring(suite_data.failures), FAILED_COLOR, DEFAULT_BG_COLOR) },
          { bmsg(" failure(s):", WHITE, DEFAULT_BG_COLOR) }
        )
      )

      for _, fail_name in ipairs(suite_data.fail_names) do
        print()
        term.blit(
          combine_blit(
            { bmsg("  ", WHITE, DEFAULT_BG_COLOR) },
            { bmsg(fail_name, TEST_NAME_COLOR, DEFAULT_BG_COLOR) }
          )
        )
      end
    end
  end

  -- Count the number of disabled tests.
  local disabled_tests = 0
  for _, suite in ipairs(suites) do
    for _, test in ipairs(suite.tests) do
      if not test.enabled then
        disabled_tests = disabled_tests + 1
      end
    end
  end

  -- Print the number of disabled tests.
  if disabled_tests > 0 then
    print()
    term.blit(
      combine_blit(
        { bmsg(disabled_tests > 1 and "There were " or "There was ", WHITE, DEFAULT_BG_COLOR) },
        { bmsg(tostring(disabled_tests), FAILED_COLOR, DEFAULT_BG_COLOR) },
        { bmsg(disabled_tests > 1 and " disabled tests." or " disabled test.", WHITE, DEFAULT_BG_COLOR) }
      )
    )
  end

  print() -- put the cursor on a new line
end

return logger
