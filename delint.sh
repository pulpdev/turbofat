#!/bin/sh
# analyzes code for stylistic errors, printing them to the console

# functions missing return type
grep -R -n "^func.*):$" --include="*.gd" ./project/src

# long lines
grep -R -n "^.\{120,\}$" --include="*.gd" ./project/src
grep -R -n "^	.\{116,\}$" --include="*.gd" ./project/src
grep -R -n "^		.\{112,\}$" --include="*.gd" ./project/src
grep -R -n "^			.\{108,\}$" --include="*.gd" ./project/src
grep -R -n "^				.\{104,\}$" --include="*.gd" ./project/src
grep -R -n "^					.\{100,\}$" --include="*.gd" ./project/src

# fields/variables missing type hint. includes a list of whitelisted type hint omissions
grep -R -n "var [^:]* = " --include="*.gd" ./project/src \
  | grep -v " = parse_json(" \
  | grep -v "chat-event.gd:73"

find ./project/src -name *.TMP
find ./project/src -name *.gd~

# project settings which are enabled temporarily, but shouldn't be pushed
grep "emulate_touch_from_mouse=true" ./project/project.godot 
