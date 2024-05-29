local suite = require "Framework"
local working_dir = shell.dir()

local argument = ...
if argument == "-v" or argument == "--verbose" or argument == "-verbose" then
  require "Framework.logger".verbose = true
end

suite.load_tests(fs.combine(working_dir, "tests"))

suite.run_all_suites()