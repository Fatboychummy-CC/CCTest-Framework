local mock = require "Framework.mock" ---@type mock_objects

local mock_obj = mock.new("John", {})

---@diagnostic disable: undefined-global We will be using a bunch of globals here defined in another location.

suite.suite "Mock objects"
  "NOOT NOOT" (suite.MODS.DISABLE, function()
    mock_obj.MOCK_METHOD("test")
      .RETURN_ONCE("test")
      .EXPECT_CALL(1)

    EXPECT_EQ(mock_obj.test(), "test")
  end)