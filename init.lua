--- === ControlEscape ===
---
--- Make the `control` key more useful: If the `control` key is tapped, treat it
--- as the `escape` key. If the `control` key is held down and used in
--- combination with another key, then provide the normal `control` key
--- behavior.

local obj={}
obj.__index = obj

-- Metadata
obj.name = 'ControlEscape'
obj.version = '0.1'
obj.author = 'Jason Rudolph <jason@jasonrudolph.com>'
obj.homepage = 'https://github.com/jasonrudolph/ControlEscape.spoon'
obj.license = 'MIT - https://opensource.org/licenses/MIT'

function obj:init()
  self.sendEscape = false
  self.lastModifiers = {}

  -- If `control` is held for this long, don't send `escape`
  local CANCEL_DELAY_SECONDS = 0.150
  self.controlKeyTimer = hs.timer.delayed.new(CANCEL_DELAY_SECONDS, function()
    self.sendEscape = false
  end)

  -- Create an eventtap to run each time the modifier keys change (i.e., each
  -- time a key like control, shift, option, or command is pressed or released)
  self.controlTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged},
    function(event)
      local newModifiers = event:getFlags()

      -- If this change to the modifier keys does not invole a *change* to the
      -- up/down state of the `control` key (i.e., it was up before and it's
      -- still up, or it was down before and it's still down), then don't take
      -- any action.
      if self.lastModifiers['ctrl'] == newModifiers['ctrl'] then
        return false
      end

      -- If the `control` key has changed to the down state, then start the
      -- timer. If the `control` key changes to the up state before the timer
      -- expires, then send `escape`.
      if not self.lastModifiers['ctrl'] then
        self.lastModifiers = newModifiers
        self.sendEscape = true
        self.controlKeyTimer:start()
      else
        if self.sendEscape then
          hs.eventtap.keyStroke({}, 'escape', 0)
        end
        self.lastModifiers = newModifiers
        self.controlKeyTimer:stop()
      end
      return false
    end
  )

  -- Create an eventtap to run each time a normal key (i.e., a non-modifier key)
  -- enters the down state. We only want to send `escape` if `control` is
  -- pressed and released in isolation. If `control` is pressed in combination
  -- with any other key, we don't want to send `escape`.
  self.keyDownEventTap = hs.eventtap.new({hs.eventtap.event.types.keyDown},
    function(event)
      self.sendEscape = false
      return false
    end
  )
end

--- ControlEscape:start()
--- Method
--- Start sending `escape` when `control` is pressed and released in isolation
function obj:start()
  self.controlTap:start()
  self.keyDownEventTap:start()
end

--- ControlEscape:stop()
--- Method
--- Stop sending `escape` when `control` is pressed and released in isolation
function obj:stop()
  -- Stop monitoring keystrokes
  self.controlTap:stop()
  self.keyDownEventTap:stop()

  -- Reset state
  self.controlKeyTimer:stop()
  self.sendEscape = false
  self.lastModifiers = {}
end

return obj
