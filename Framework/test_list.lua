--- This module compiles test data into a table of tests.

---@generic T
---@alias array_of<T>  table<number, T>

---@alias test_status
---| '"pass"' # The test passed.
---| '"fail"' # The test failed.
---| '"error"' # The test errored.
---| '"disabled"' # The test was disabled (and will be skipped).
---| '"new"' # The test has not been run yet.
---| '"running"' # The test is currently running.

---@class test_data
---@field name string The name of the test.
---@field coro thread The coroutine for the test.
---@field status test_status The status of the test.
---@field error string|nil The error message, if the test errored.
---@field failures array_of<string> The failure messages, if the test failed.

---@class test_list
---@field tests array_of<test_data> The tests.
local test_list = {}
