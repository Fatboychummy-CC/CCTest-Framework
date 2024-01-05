---@diagnostic disable: undefined-global We will be using a bunch of globals here defined in another location.

-- This test file exists to ensure all methods are defined in the suite 
-- (currently the list of what functions should exist are in the README.md file)
-- We are not testing that they work, just that they exist.

suite.suite "Methods Exist"
  "PASS" (function()
    if type(PASS) ~= "function" then
      FAIL("PASS is not a function.")
    end
  end)
  "FAIL" (function()
    if type(FAIL) ~= "function" then
      FAIL("FAIL is not a function.")
    end
  end)
  "END" (function()
    if type(END) ~= "function" then
      FAIL("END is not a function.")
    end
  end)
  "EQ" (function()
    if type(EXPECT_EQ) ~= "function" then
      FAIL("EXPECT_EQ is not a function.")
    end
    if type(ASSERT_EQ) ~= "function" then
      FAIL("ASSERT_EQ is not a function.")
    end
  end)
  "NEQ" (function()
    if type(EXPECT_NEQ) ~= "function" then
      FAIL("EXPECT_NEQ is not a function.")
    end
    if type(ASSERT_NEQ) ~= "function" then
      FAIL("ASSERT_NEQ is not a function.")
    end
  end)
  "TRUE" (function()
    if type(EXPECT_TRUE) ~= "function" then
      FAIL("EXPECT_TRUE is not a function.")
    end
    if type(ASSERT_TRUE) ~= "function" then
      FAIL("ASSERT_TRUE is not a function.")
    end
  end)
  "FALSE" (function()
    if type(EXPECT_FALSE) ~= "function" then
      FAIL("EXPECT_FALSE is not a function.")
    end
    if type(ASSERT_FALSE) ~= "function" then
      FAIL("ASSERT_FALSE is not a function.")
    end
  end)
  "TRUTHY" (function()
    if type(EXPECT_TRUTHY) ~= "function" then
      FAIL("EXPECT_TRUTHY is not a function.")
    end
    if type(ASSERT_TRUTHY) ~= "function" then
      FAIL("ASSERT_TRUTHY is not a function.")
    end
  end)
  "FALSY" (function()
    if type(EXPECT_FALSY) ~= "function" then
      FAIL("EXPECT_FALSY is not a function.")
    end
    if type(ASSERT_FALSY) ~= "function" then
      FAIL("ASSERT_FALSY is not a function.")
    end

    -- aliases
    if type(EXPECT_FALSEY) ~= "function" then
      FAIL("EXPECT_FALSEY is not a function.")
    end
    if type(ASSERT_FALSEY) ~= "function" then
      FAIL("ASSERT_FALSEY is not a function.")
    end
  end)
  "NIL" (function()
    if type(EXPECT_NIL) ~= "function" then
      FAIL("EXPECT_NIL is not a function.")
    end
    if type(ASSERT_NIL) ~= "function" then
      FAIL("ASSERT_NIL is not a function.")
    end
  end)
  "NOT_NIL" (function()
    if type(EXPECT_NOT_NIL) ~= "function" then
      FAIL("EXPECT_NOT_NIL is not a function.")
    end
    if type(ASSERT_NOT_NIL) ~= "function" then
      FAIL("ASSERT_NOT_NIL is not a function.")
    end
  end)
  "THROWS" (function()
    if type(EXPECT_THROWS) ~= "function" then
      FAIL("EXPECT_THROWS is not a function.")
    end
    if type(ASSERT_THROWS) ~= "function" then
      FAIL("ASSERT_THROWS is not a function.")
    end
  end)
  "THROWS_MATCH" (function()
    if type(EXPECT_THROWS_MATCH) ~= "function" then
      FAIL("EXPECT_THROWS_MATCH is not a function.")
    end
    if type(ASSERT_THROWS_MATCH) ~= "function" then
      FAIL("ASSERT_THROWS_MATCH is not a function.")
    end
  end)
  "NO_THROW" (function()
    if type(EXPECT_NO_THROW) ~= "function" then
      FAIL("EXPECT_NO_THROW is not a function.")
    end
    if type(ASSERT_NO_THROW) ~= "function" then
      FAIL("ASSERT_NO_THROW is not a function.")
    end
  end)
  "TYPE" (function()
    if type(EXPECT_TYPE) ~= "function" then
      FAIL("EXPECT_TYPE is not a function.")
    end
    if type(ASSERT_TYPE) ~= "function" then
      FAIL("ASSERT_TYPE is not a function.")
    end
  end)
  "EVENT" (function()
    if type(EXPECT_EVENT) ~= "function" then
      FAIL("EXPECT_EVENT is not a function.")
    end
    if type(ASSERT_EVENT) ~= "function" then
      FAIL("ASSERT_EVENT is not a function.")
    end
  end)
  "TIMEOUT" (function()
    if type(EXPECT_TIMEOUT) ~= "function" then
      FAIL("EXPECT_TIMEOUT is not a function.")
    end
    if type(ASSERT_TIMEOUT) ~= "function" then
      FAIL("ASSERT_TIMEOUT is not a function.")
    end
  end)
  "GT" (function()
    if type(EXPECT_GT) ~= "function" then
      FAIL("EXPECT_GT is not a function.")
    end
    if type(ASSERT_GT) ~= "function" then
      FAIL("ASSERT_GT is not a function.")
    end
  end)
  "GE" (function()
    if type(EXPECT_GE) ~= "function" then
      FAIL("EXPECT_GE is not a function.")
    end
    if type(ASSERT_GE) ~= "function" then
      FAIL("ASSERT_GE is not a function.")
    end
  end)
  "LT" (function()
    if type(EXPECT_LT) ~= "function" then
      FAIL("EXPECT_LT is not a function.")
    end
    if type(ASSERT_LT) ~= "function" then
      FAIL("ASSERT_LT is not a function.")
    end
  end)
  "LE" (function()
    if type(EXPECT_LE) ~= "function" then
      FAIL("EXPECT_LE is not a function.")
    end
    if type(ASSERT_LE) ~= "function" then
      FAIL("ASSERT_LE is not a function.")
    end
  end)
  "FLOAT_EQ" (function()
    if type(EXPECT_FLOAT_EQ) ~= "function" then
      FAIL("EXPECT_FLOAT_EQ is not a function.")
    end
    if type(ASSERT_FLOAT_EQ) ~= "function" then
      FAIL("ASSERT_FLOAT_EQ is not a function.")
    end
  end)
  "MATCH" (function()
    if type(EXPECT_MATCH) ~= "function" then
      FAIL("EXPECT_MATCH is not a function.")
    end
    if type(ASSERT_MATCH) ~= "function" then
      FAIL("ASSERT_MATCH is not a function.")
    end
  end)
  "DEEP_EQ" (function()
    if type(EXPECT_DEEP_EQ) ~= "function" then
      FAIL("EXPECT_DEEP_EQ is not a function.")
    end
    if type(ASSERT_DEEP_EQ) ~= "function" then
      FAIL("ASSERT_DEEP_EQ is not a function.")
    end
  end)