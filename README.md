# CCTest-Framework

A simple testing framework for ComputerCraft.

## Usage

### Creating a test suite

To use this framework, you must create test "suites" that contain the tests that
you want to run.

#### Syntax
  
```lua
local suite = require("suite") -- Import the suite

local mySuite = suite.suite "My Suite" -- Create a new suite
  "Test name" (function() -- Add a test to the suite, with the name "Test name"
    -- Test code
  end)
  -- ...
```

### Package path

To use the framework, you must add your libraries folder to the package path,
as well as the framework's folder.

For a simple function that can add these paths, see the `add_paths` function
below.

```lua
local function add_paths(...)
  local paths = {...}
  local path = package.path
  local formatter = "%s;%s/?.lua;%s/?/init.lua"

  for _, v in ipairs(paths) do
    path = formatter:format(path, v, v)
  end

  package.path = path
end

-- Usage
add_paths("path/to/libraries", "path/to/framework")
```

### Running tests

You can run individual suites, or all suites at once. To run a suite, use the
`run` function.

```lua
local suite = require("suite")

local mySuite = suite.suite "My Suite"
  "Test name" (function()
    -- Test code
  end)
  -- ...

mySuite.run() -- Run the suite
```

To run all suites, use the `run_all` function.

```lua
local suite = require("suite")

suite.run_all() -- Run all loaded suites
```

### Assertions

The framework provides a few assertions that can be used in tests. Each of these
assertions will *instantly* stop the test if they fail.

All assertions can be used as expectations instead, by swapping the `ASSERT_`
prefix with `EXPECT_`. Expectations will not stop the test if they fail, but
will instead mark the test as failed. The test will continue to run, and will
fail if it reaches the end of the test without `PASS()`ing.

#### `ASSERT_EQ`

Asserts that two values are equal.

```lua
ASSERT_EQ(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_EQ(1, 1) -- pass
    ASSERT_EQ(1, 2) -- fail
  end)
```

#### `ASSERT_NE`

Asserts that two values are not equal.

```lua
ASSERT_NE(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_NE(1, 1) -- fail
    ASSERT_NE(1, 2) -- pass
  end)
```

#### `ASSERT_TRUE`

Asserts that a value is true.

```lua
ASSERT_TRUE(value: boolean)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_TRUE(true) -- pass
    ASSERT_TRUE(false) -- fail
    ASSERT_TRUE("non-boolean") -- fail
  end)
```

#### `ASSERT_FALSE`

Asserts that a value is false.

```lua
ASSERT_FALSE(value: boolean)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_FALSE(true) -- fail
    ASSERT_FALSE(false) -- pass
    ASSERT_FALSE("non-boolean") -- fail
  end)
```

#### `ASSERT_TRUTHY`

Asserts that a value is truthy. This is equivalent to 
`ASSERT_TRUE(value ~= nil and value ~= false)`.

```lua
ASSERT_TRUTHY(value: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_TRUTHY(true) -- pass
    ASSERT_TRUTHY("non-boolean, but truthy value") -- pass
    ASSERT_TRUTHY(false) -- fail
    ASSERT_TRUTHY(nil) -- fail
  end)
```

#### `ASSERT_FALSY`

Asserts that a value is falsy. This is equivalent to
`ASSERT_FALSE(value ~= nil and value ~= false)`.

Note that `ASSERT_FALSEY` also exists, and is an alias for `ASSERT_FALSY`.

```lua
ASSERT_FALSY(value: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_FALSY(true) -- fail
    ASSERT_FALSY("non-boolean, but truthy value") -- fail
    ASSERT_FALSY(false) -- pass
    ASSERT_FALSY(nil) -- pass
  end)
```

#### `ASSERT_THROWS`

Asserts that a function throws any error. Variadic arguments are passed to the
function upon running it.

```lua
ASSERT_THROWS(func: fun(...: any), ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_THROWS(function() error("test") end) -- pass
    ASSERT_THROWS(function() end) -- fail
  end)
```

#### `ASSERT_THROWS_MATCH`

Asserts that a function throws an error that matches a pattern. Variadic
arguments are passed to the function upon running it.

```lua
ASSERT_THROWS_MATCH(func: fun(...: any), pattern: string, ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_THROWS_MATCH(function() error("test") end, "test") -- pass
    ASSERT_THROWS_MATCH(function() error("test") end, "no match") -- fail
    ASSERT_THROWS_MATCH(function() end, "test") -- fail
  end)
```

#### `ASSERT_TYPE`

Asserts that a value is of a certain type (or types).

```lua
ASSERT_TYPE(value: any, ...: string)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_TYPE(1, "number") -- pass
    ASSERT_TYPE("some string", "string") -- pass
    ASSERT_TYPE({}, "table") -- pass

    ASSERT_TYPE(1, "number", "string") -- pass
    ASSERT_TYPE("some string", "number", "string") -- pass

    ASSERT_TYPE(1, "string") -- fail
    ASSERT_TYPE("string", "number") -- fail
    ASSERT_TYPE({}, "number") -- fail

    ASSERT_TYPE({}, "number", "string") -- fail
  end)
```

#### `ASSERT_EVENT`

Asserts that an event is emitted within a given timeframe while running a given
function.

```lua
EVENT(func: fun(...: any), event: string, timeout: number, ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_EVENT(function() os.queueEvent("test") end, "test", 1) -- pass
    ASSERT_EVENT(function() end, "test", 1) -- fail
  end)
```

#### `ASSERT_TIMEOUT`

Asserts that a function takes no longer than a given amount of time to run.
Variadic arguments are passed to the function upon running it.

```lua
ASSERT_TIMEOUT(func: fun(...: any), timeout: number, ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_TIMEOUT(function() end, 1) -- pass
    ASSERT_TIMEOUT(function() sleep(2) end, 1) -- fail
  end)
```

#### `ASSERT_GT`

Asserts that a value is greater than another value.

```lua
ASSERT_GT(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_GT(2, 1) -- pass
    ASSERT_GT(1, 2) -- fail
    ASSERT_GT(1, 1) -- fail
  end)
```

#### `ASSERT_GE`

Asserts that a value is greater than or equal to another value.

```lua
ASSERT_GE(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_GE(2, 1) -- pass
    ASSERT_GE(1, 2) -- fail
    ASSERT_GE(1, 1) -- pass
  end)
```

#### `ASSERT_LT`

Asserts that a value is less than another value.

```lua
ASSERT_LT(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_LT(1, 2) -- pass
    ASSERT_LT(2, 1) -- fail
    ASSERT_LT(1, 1) -- fail
  end)
```

#### `ASSERT_LE`

Asserts that a value is less than or equal to another value.

```lua
ASSERT_LE(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_LE(1, 2) -- pass
    ASSERT_LE(2, 1) -- fail
    ASSERT_LE(1, 1) -- pass
  end)
```

#### `ASSERT_FLOAT_EQ`

Asserts that two floating point numbers are equal within a given tolerance. The
default tolerance is 0.00001.

Use this instead of `ASSERT_EQ` for floating point numbers. `0.1 + 0.2` is not
*exactly* equal to `0.3` in Lua, so `ASSERT_EQ(0.1 + 0.2, 0.3)` will fail.

```lua
ASSERT_FLOAT_EQ(value_a: any, value_b: any, tolerance: number = 0.00001)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_FLOAT_EQ(1.00001, 1.00002) -- pass
    ASSERT_FLOAT_EQ(1.00001, 1.00002, 0.000001) -- fail
  end)
```

#### `ASSERT_MATCH`

Asserts that a string matches a pattern (or any of a list of patterns).

```lua
ASSERT_MATCH(value: string, ...: string)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_MATCH("test", "test") -- pass
    ASSERT_MATCH("test", "no match") -- fail
  end)
```

#### `ASSERT_DEEP_EQ`

Asserts that two tables are deeply equal (i.e: all keys in table A match all
keys in table B, and vice versa for both keys and values).

This method also checks subtable equality in each table.

```lua
ASSERT_DEEP_EQ(value_a: table, value_b: table)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_DEEP_EQ({a = 1, b = 2}, {a = 1, b = 2}) -- pass
    ASSERT_DEEP_EQ({a = 1, b = 2}, {a = 1, b = 3}) -- fail
    ASSERT_DEEP_EQ({a = 1}, {a = 1, b = 2}) -- fail
    ASSERT_DEEP_EQ({a = 1, b = 2}, {a = 1}) -- fail
  end)
```

### Other functions

#### `PASS`

Forcefully passes the test, even if it was marked as failed.

```lua
PASS()
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    EXPECT_EQ(1, 2) -- fail
    PASS() -- the test is now marked as passed, even though an expectation failed.
  end)
```

#### `FAIL`

Forcefully fails the test.

```lua
FAIL()
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    FAIL() -- fail
  end)
```

### Test modifiers

Multiple modifiers can be applied to a test. For example, you can apply both
`REPEAT` and `TIMEOUT` to a test like so:
  
```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.REPEAT(10), suite.MODS.TIMEOUT(3), function()
    -- ...
  end)
```

and the test will be ran 10 times, and will fail if any single test takes longer
than 3 seconds to run.

#### `ONLY`

If a test is marked with `ONLY`, only that test will be run. All other tests
will be ignored (unless they have `ONLY` as well).

```lua
suite.suite "My Suite"
  "Test name" (function()
    -- ...
  end)
  "Test name 2" (suite.MODS.ONLY, function()
    -- ...
  end)
```

#### `DISABLE`

If a test is marked with `DISABLE`, that test will be ignored.

```lua
suite.suite "My Suite"
  "Test name" (function()
    -- ...
  end)
  "Test name 2" (suite.MODS.DISABLE, function()
    -- ...
  end)
```

#### `SKIP`

If a test is marked with `SKIP`, that test will be skipped. The test will be
marked as passed, but will not be run.

```lua
suite.suite "My Suite"
  "Test name" (function()
    -- ...
  end)
  "Test name 2" (suite.MODS.SKIP, function()
    -- ...
  end)
```

#### `TIMEOUT`

If a test is marked with `TIMEOUT`, the test will fail if it takes longer than
the given amount of time to run.

```lua
suite.MODS.TIMEOUT(timeout: number)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.TIMEOUT(1), function()
    -- ...
  end)
```

#### `REPEAT`

If a test is marked with `REPEAT`, the test will be run multiple times.

```lua
suite.MODS.REPEAT(times: number)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.REPEAT(10), function()
    -- ...
  end)
```

#### `REPEAT_TIMEOUT`

Similar to `(suite.REPEAT(x), suite.TIMEOUT(y))`, but will fail if the entire
batch of tests takes longer than the given amount of time to run.

```lua
suite.MODS.REPEAT_TIMEOUT(times: number, timeout: number)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.REPEAT_TIMEOUT(10, 3), function()
    -- ...
  end)
```

#### `REPEAT_UNTIL_FAIL`

If a test is marked with `REPEAT_UNTIL_FAIL`, the test will be run multiple
times until it fails. Not wholely useful, but if you have a bug that only seems
to happen sometimes, this can be useful to see if you can get it to trigger.

It does, however, also include a timeout. If the test takes longer than the
given amount of time to run, it will be marked as passed (assuming no other
failures occurred).

```lua
suite.MODS.REPEAT_UNTIL_FAIL(timeout: number)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.REPEAT_UNTIL_FAIL(10), function()
    -- ...
  end)
```