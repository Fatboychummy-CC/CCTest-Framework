--- A simple mocking framework for use in CCTest.


---@class mock_events
--- Mockable events, shorthands for `os.queueEvent`. Makes it more obvious that events are being queued for a reason.
--- Also gives type annotations in editors which support it, which is nice.
local mock = {}

---@class multi_mock_events Mock multiple events at once via one call.
mock.multi = {}

--- Mock a `mouse_click` event (when a user pushes the mouse down but does not lift it up)
---@param x number The x position of the click.
---@param y number The y position of the click.
---@param button number The button that was clicked.
function mock.mouse_click(x, y, button)
  os.queueEvent("mouse_click", x, y, button)
end

--- Mock a `mouse_up` event (when a user lifts the mouse button up after pushing it down)
---@param x number The x position of the click.
---@param y number The y position of the click.
---@param button number The button that was clicked.
function mock.mouse_up(x, y, button)
  os.queueEvent("mouse_up", x, y, button)
end

--- Mock a `mouse_drag` event (when a user pushes the mouse down, then moves it while still holding it down)
---@param x number The x position of the click.
---@param y number The y position of the click.
---@param button number The button that was clicked.
function mock.mouse_drag(x, y, button)
  os.queueEvent("mouse_drag", x, y, button)
end

--- Mock a `mouse_scroll` event (when a user scrolls the mouse wheel)
---@param direction integer The direction of the scroll. Negative is up, positive is down.
---@param x number The x position of the scroll.
---@param y number The y position of the scroll.
function mock.mouse_scroll(direction, x, y)
  os.queueEvent("mouse_scroll", direction, x, y)
end

--- Mock a `key` event -- Note that this does not fully simulate the char event that is sometimes sent after a key event.
---@param key integer The keycode that was pressed
---@param held boolean Whether or not the key was held down
function mock.key(key, held)
  os.queueEvent("key", key, held)
end

--- Mock a key_up event
---@param key integer The keycode that was released
function mock.key_up(key)
  os.queueEvent("key_up", key)
end

--- Mock a `char` event
---@param char string The character that was typed
function mock.char(char)
  os.queueEvent("char", char)
end

--- Mock a full keypress event (key and char)
---@param key integer The keycode that was pressed
---@param held boolean Whether or not the key was held down
function mock.multi.keypress(key, held)
  mock.key(key, held)
  local name = keys.getName(key)
  if name then
    mock.char(name)
  end
end

return mock