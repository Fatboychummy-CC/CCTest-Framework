local suite = require "Framework"
local working_dir = shell.dir()

suite.load_tests(fs.combine(working_dir, "tests"))

suite.run_all_suites()

print("Done.")