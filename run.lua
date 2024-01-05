local suite = require "Framework"
local argument = ...

local working_dir = shell.dir()

if argument == "test_main" then
  suite.load_tests(fs.combine(working_dir, "tests_main"))

  suite.run_all_suites()
elseif argument == "test_alt" or argument == "test_alternate" then
  -- Manually require each file in tests_alternate folder.
  local files = fs.list(fs.combine(working_dir, "tests_alternate"))

  for _, file in ipairs(files) do
    local full_path = fs.combine(working_dir, "tests_alternate", file)
    if not fs.isDir(full_path) then
      require("tests_alternate." .. file:sub(1, -5))
    end
  end

  suite.run_all_suites()
end

suite.cleanup()

print("Done.")