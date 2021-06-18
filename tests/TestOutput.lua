cctest.newSuite "Testing Testing 1-2-3"
  "PRINT_STUFF_PASS" (function()
    print("ALALALALFDSKJIKJG")
    print("ay")

    PASS()
  end)
  "PRINT_STUFF_FAIL" (function()
    print("ALALALALFDSKJIKJG")
    print("ay")

    FAIL()
  end)
  "SET_CURSOR_PASS" (function()
    term.setCursorPos(math.random(1, 10), math.random(1, 10))

    PASS()
  end)
  "SET_CURSOR_FAIL" (function()
    term.setCursorPos(math.random(1, 10), math.random(1, 10))

    FAIL()
  end)
  "BOTH_PASS" (function()
    term.setCursorPos(math.random(1, 10), math.random(1, 10))
    print("ALALALALFDSKJIKJG")
    print("ay")

    PASS()
  end)
  "BOTH_FAIL" (function()
    term.setCursorPos(math.random(1, 10), math.random(1, 10))
    print("ALALALALFDSKJIKJG")
    print("ay")

    FAIL()
  end)
