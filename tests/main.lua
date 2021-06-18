package.path = package.path .. ";/?/init.lua"

_G.cctest = require "Framework"

require "TestTest.lua"
require "TestOutput.lua"

cctest.runAllTests(...)
