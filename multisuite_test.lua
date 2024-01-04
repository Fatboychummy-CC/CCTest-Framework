local suite = require "Framework.suite"

---@diagnostic disable: undefined-global We will be using a bunch of globals here defined in another location.

local mySuite = suite.suite "Second Suite Test"
  "Just run a test." (function()
    PASS()
  end)
  "Fail a test." (function()
    FAIL()
  end)