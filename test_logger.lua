---@diagnostic disable This file is a test file, and as such will have errors.

local logger = require "Framework.logger"

local DELAY_TIME = 0.05

-- Quick test file that fakes a test being logged as it changes.

logger.new_suite("test_logger", 99999999)

logger.new_test "running"
sleep(DELAY_TIME)
logger.update_status "running"

logger.new_test "pass"
sleep(DELAY_TIME)
logger.update_status "pass"

logger.new_test "fail"
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "error"
sleep(DELAY_TIME)
logger.update_status "error"

logger.new_test "disabled"
sleep(DELAY_TIME)
logger.update_status "disabled"

logger.new_test "unknown"
sleep(DELAY_TIME)
logger.update_status "AKJFHALKJHFALKJHFNSJKLHJFKLASN"

logger.new_test "assertions"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.log_assertion("ASSERT_SOMETHING", true)
sleep(DELAY_TIME)
logger.log_assertion("ASSERT_SOMETHING", false, "This is a failure message.")
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "expectations"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING", true)
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING", false, "This is a failure message.")
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING_ELSE", false, "This is a failure message, part 2.")
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "stacktrace"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.update_status "fail"
logger.log_stacktrace("This is a stacktrace.\n  A second line.\n  A third line.")

logger.verbose = true
print("#####")

logger.new_test "running-verbose"
sleep(DELAY_TIME)
logger.update_status "running"

logger.new_test "pass-verbose"
sleep(DELAY_TIME)
logger.update_status "pass"

logger.new_test "fail-verbose"
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "error-verbose"
sleep(DELAY_TIME)
logger.update_status "error"

logger.new_test "disabled-verbose"
sleep(DELAY_TIME)
logger.update_status "disabled"

logger.new_test "unknown-verbose"
sleep(DELAY_TIME)
logger.update_status "AKJFHALKJHFALKJHFNSJKLHJFKLASN"

logger.new_test "assertions-verbose"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.log_assertion("ASSERT_SOMETHING", true)
sleep(DELAY_TIME)
logger.log_assertion("ASSERT_SOMETHING", false, "This is a failure message.")
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "expectations-verbose"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING", true)
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING", false, "This is a failure message.")
sleep(DELAY_TIME)
logger.log_expectation("EXPECT_SOMETHING_ELSE", false, "This is a failure message, part 2.")
sleep(DELAY_TIME)
logger.update_status "fail"

logger.new_test "stacktrace-verbose"
sleep(DELAY_TIME)
logger.update_status "running"
sleep(DELAY_TIME)
logger.update_status "fail"
logger.log_stacktrace("This is a stacktrace.\n  A second line.\n  A third line.")


logger.verbose = false
print()print("#####")

logger.new_test "log_error"
sleep(DELAY_TIME)
logger.log_error "This is an error message."

logger.new_test "log_failure"
sleep(DELAY_TIME)
logger.log_failure "This is a failure message."

logger.new_test "log_error-verbose"
sleep(DELAY_TIME)
logger.log_error "This is an error message."

logger.new_test "log_failure-verbose"
sleep(DELAY_TIME)
logger.log_failure "This is a failure message."

logger.new_test "log-stacktrace"
logger.log_stacktrace("This is a stacktrace.\n  A second line.\n  A third line.")

--- Mock list of suites
---@type test_suite[]
local suites = {
  {
    name = "some suite",
    tests = {
      {
        status = "pass",
        name = "pass",
        error = nil,
        failures = {},
      },
      {
        status = "fail",
        name = "some failing test",
        error = nil,
        failures = {},
      },
      {
        status = "fail",
        name = "some other failing test",
        error = nil,
        failures = {},
      }
    }
  },
  {
    name = "some other suite",
    tests = {
      {
        status = "pass",
        name = "pass",
        error = nil,
        failures = {},
      },
      {
        status = "fail",
        name = "some failing test of suite 2",
        error = nil,
        failures = {},
      }
    }
  }
}

logger.log_results(suites)