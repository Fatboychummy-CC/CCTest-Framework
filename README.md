# CCTest-Framework

A simple testing framework for ComputerCraft.

Note: This is meant to be used with CraftOS-PC and will attach a monitor
using periphemu.

## Usage

### Creating a test suite

To use this framework, you must create test "suites" that contain the tests that
you want to run.

#### Syntax

This test framework can be used in two ways: As a single file, or where it
shines best: as a set of files contained within a folder.

The design of the framework is such that you can put all your tests in a folder 
in the root alongside your main program file. Then, in your main program, you
can add something like the following to the top:
  
```lua
local args = {...}

if args[1] == "test" then
  local suite = require "suite"

  suite.load_tests("/path/to/tests")

  suite.run_all_suites()
  return
end

-- your main program
```

This allows you to unit test libraries that your main program imports easily, in
a way that is similar to testing with a makefile (i.e: `make tests`).

Alternatively, you can put all this in a seperate test file and run it:

```lua
local suite = require "suite"
suite.load_tests("/path/to/tests")
suite.run_all_suites()
```

##### Folder file structure

When using the folder structure, the framework will inject all the suite-related
methods into the file's environment. This means that you can use the `suite`
variable to create suites without needing to require it. For example:

```lua
suite "My Suite"
  "Test name" (function()
    -- Test code
  end)
```

That's it, that's all that is needed in your test file. The framework will
automatically load the file with the proper environment variables, then run it.

##### Single-file testing

You can, optionally, choose to put all your tests into a single file like a
madman. This is not recommended as it will get cluttered, but it is possible. In
order to do this, structure your file like so:
  
```lua
local suite = require("suite") -- Import the suite

local mySuite = suite.suite "My Suite" -- Create a new suite
  "Test name" (function() -- Add a test to the suite, with the name "Test name"
    -- Test code
  end)
  -- ...

-- other suites...

suite.run_all_suites() -- Run all loaded suites

-- or, if you want to run a single suite:

mySuite.run() -- Run the suite
```

This method is slightly less optimal, as it injects all methods into the `_ENV`
variable. It does do cleanup afterwards though.

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

To run all suites, use the `run_all_suites` function.

```lua
local suite = require("suite")

suite.run_all_suites() -- Run all loaded suites
```

### Assertions

The framework provides a few assertions that can be used in tests. Each of these
assertions will *instantly* stop the test if they fail.

All assertions can be used as expectations instead, by swapping the `ASSERT_`
prefix with `EXPECT_`. Expectations will not stop the test if they fail, but
will instead mark the test as failed. The test will continue to run, and will
fail if it reaches the end of the test without `PASS()`ing.

```diff
===================================================================
@@                            WARNING                            @@
===================================================================
- Assertations and expectations CANNOT be used outside of a test. -
- Doing so will cause your program to hang.                       -
===================================================================
```

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

#### `ASSERT_NEQ`

Asserts that two values are not equal.

```lua
ASSERT_NEQ(value_a: any, value_b: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_NEQ(1, 1) -- fail
    ASSERT_NEQ(1, 2) -- pass
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

#### `ASSERT_NIL`

Asserts that a value is nil.

```lua
ASSERT_NIL(value: boolean)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_NIL(true) -- fail
    ASSERT_NIL(32) -- fail
    ASSERT_NIL(nil) -- pass
  end)
```

#### `ASSERT_NOT_NIL`

Asserts that a value is not nil.

```lua
ASSERT_NOT_NIL(value: boolean)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_NOT_NIL(true) -- pass
    ASSERT_NOT_NIL(32) -- pass
    ASSERT_NOT_NIL("non-boolean") -- pass
    ASSERT_NOT_NIL(nil) -- fail
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

#### `ASSERT_NO_THROW`

Asserts that a given function *does not* throw an error.

```lua
ASSERT_NO_THROW(func: fun(...: any), ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    ASSERT_NO_THROW(function() error("test") end) -- fail
    ASSERT_NO_THROW(function() end) -- pass
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

Asserts that an event is emitted some time during this test. Variadic arguments
can be used for further comparison of the event. It is recommended that, if 
using this assertion, you should also include the `EXTEND` test modifier, to
ensure that the test does not end before the event is emitted.

```lua
ASSERT_EVENT(event: string, ...: any)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.EXTEND(0.1), function()
    ASSERT_EVENT("test")

    os.queueEvent("test") -- pass
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
FAIL(reason: string = "Manual failure.")
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    FAIL() -- fail
  end)
```

#### `END`

Forcefully end the test. This is equivalent to an assertion failing.

```lua
END(reason: string = "Manual failure.")
```

```lua
suite.suite "My Suite"
  "Test name" (function()
    END() -- fail
  end)
```

### Test modifiers

Test modifiers change the way a test works. They are applied to a test by
placing them before the test function. 

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
will be ignored (unless they have `ONLY` as well). Useful for debugging a single
issue.

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
  "Test name" (suite.MODS.DISABLE, function()
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

#### `POST_DELAY`

Adds a delay (in seconds) to the end of the test, so the suite will not move
onto the next test for that amount of time (allowing you to view the results
of the test in the output window created, or etc.).

Equivalent to putting a `sleep(x)` at the end of your test.

```lua
suite.MODS.POST_DELAY(timeout: number)
```

```lua
suite.suite "My Suite"
  "Test name" (suite.MODS.POST_DELAY(2), function()
    -- ...
  end)
```

### Mocking

The framework provides a simple mocking system that can be used to mock objects
and functions. To use it, require `Framework.mock`:

```lua
local mock = require("Framework.mock")
```

#### Mocking an object

To create a mock object, call `mock.new` with a table of properties to mock.
Methods can be mocked by calling `mock_object.MOCK_METHOD` with the arguments
being the input types.

```lua
local mock = require("Framework.mock")

local mock_object = mock.new {
  some_property = 32
}

mock_object.MOCK_METHOD("get_some_property") -- "getter"
mock_object.MOCK_METHOD("set_some_property", "number") -- "setter"
-- Note that the above don't actually get or set `some_property`, read further
-- to see how to use them.
```

Now, if something calls `mock_object.get_some_property()` it will instead call
the mock method, whose behaviour can be defined (see below).

##### Mocking methods

When creating mocked methods, you must specify exactly what is returned and how
many times it is returned. `mock_object.MOCK_METHOD` returns a reference which
can be used to define these. If a mock method is called with no return defined,
(or the return stack is empty), it will return nothing.

```lua
local mock = require("Framework.mock")

local mock_object = mock.new {
  some_property = 32
}

local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.RETURN_ALWAYS(32) -- Return 32 every time the method is called
```

##### Expecting method calls

You can also expect a method to be called a certain number of times, with
certain arguments. This is useful for testing that a method is called with the
correct arguments.

```lua
local mock = require("Framework.mock")

local mock_object = mock.new {
  some_property = 32
}

local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.EXPECT_CALL(2) -- Expect the method to be called twice
mock_get_some_property.RETURN_ONCE(32) -- Return 32 the first time the method is called
mock_get_some_property.RETURN_ONCE(64) -- Return 64 the second time the method is called

local mock_set_some_property = mock_object.MOCK_METHOD("set_some_property")

mock_set_some_property.EXPECT_CALL(1, 64) -- Expect the method to be called once with the argument `64`
```

Now, assuming your test code was the following:

```lua
local property = mock_object.get_some_property()
mock_object.set_some_property(property * 2)
property = mock_object.get_some_property()
```

The test would pass, as the first call to `get_some_property` would return 32,
the call to `set_some_property` would be called with 64, and the second call to
`get_some_property` would return 64.

Thus, total calls to `get_some_property` would be 2, and total calls to
`set_some_property` would be 1 -- which is what we were expecting!

##### `CONNECTS`

You can also use the `CONNECTS` method to connect a mock method to a property.
Simply state if it is a getter or a setter, and it will directly alter (or
return the value of) that property.

```lua
local mock = require("Framework.mock")

local mock_object = mock.new {
  some_property = 32
}

local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.CONNECTS("getter", "some_property") -- Connect the mock method to the property

local mock_set_some_property = mock_object.MOCK_METHOD("set_some_property")

mock_set_some_property.CONNECTS("setter", "some_property") -- Connect the mock method to the property
```

This makes it so you do not have to set up `RETURN_ALWAYS` or `RETURN_ONCE` for
simple getters or setters.

##### Mock method methods

The following methods are available on mock methods:

- `RETURN_ALWAYS(...: any)`: Always return the given values when the method is
  called. Note that `RETURN_ALWAYS` can be used after `RETURN_ONCE` or
  `RETURN_N` and those will occur before the `RETURN_ALWAYS` values are
  returned.
- `RETURN_ONCE(...: any)`: Return the given values the next time the method is
  called. These can be chained to return different values on subsequent calls.
- `RETURN_N(n: number, ...: any)`: Return the given values the next `n` times
  the method is called. These can be chained to return different values on
  subsequent calls.
- `EXPECT_CALL(times: number, ...: any)`: Expect the method to be called the
  given number of times with the given arguments. These can be chained to
  expect different arguments on subsequent calls.
- `ASSERT_CALL(times: number, ...: any)`: Assert that the method was called the
  given number of times with the given arguments. These can be chained to
  assert different arguments on subsequent calls.

`EXPECT_CALL` and `ASSERT_CALL` work in the same way as a test expectation or
assertion. If `EXPECT_CALL` fails, it will fail the test, but still continue the
test. If an `ASSERT_CALL` fails, it will fail the test and stop the test.

```diff
=======================================================
@@                      WARNING                      @@
=======================================================
- The above methods CANNOT be used outside of a test. -
- Doing so will cause your program to hang.           -
=======================================================
```

##### Mock method additions

The following additions have been added to mock methods to make using them
easier (found in `mock.AID`):

- `AT_LEAST(n: number)`: Assert that the method was called at least `n` times.

```lua
local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.RETURN_ALWAYS(32) -- Return 32 every time the method is called
mock_get_some_property.EXPECT_CALL(mock.AID.AT_LEAST(2)) -- Expect the method to be called at least twice with no arguments
```

- `AT_MOST(n: number)`: Assert that the method was called at most `n` times.

```lua
local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.RETURN_ALWAYS(32) -- Return 32 every time the method is called
mock_get_some_property.EXPECT_CALL(mock.AID.AT_MOST(2)) -- Expect the method to be called at most twice with no arguments
```

- `BETWEEN(n: number, m: number)`: Assert that the method was called between `n`
  and `m` times.

```lua
local mock_get_some_property = mock_object.MOCK_METHOD("get_some_property")

mock_get_some_property.RETURN_ALWAYS(32) -- Return 32 every time the method is called
mock_get_some_property.EXPECT_CALL(mock.AID.BETWEEN(2, 4)) -- Expect the method to be called between 2 and 4 times with no arguments.
```

#### Mocking notes

1. Mock method objects can be chain called, which means you can do the
  following:

```lua
mock_object.MOCK_METHOD("get_some_property")
  .RETURN_ALWAYS(32)
  .EXPECT_CALL(2)
```

instead of doing the long-form shown in previous examples.

