#!/usr/bin/env bash

u="${USER}"
pw="$(getpw 1)"

osascript <<EOF
tell application "System Events" to tell process "GlobalProtect"
	click menu bar item 1 of menu bar 2
	click button 2 of window 1 -- Clicks either Connect or Disconnect
	delay 2.0
	tell application "System Events"
		keystroke "${u}"
		delay 0.2
		keystroke tab
		delay 0.2
		keystroke "${pw}"
		delay 0.2
	end tell
	click button 2 of window 1
end tell
EOF
