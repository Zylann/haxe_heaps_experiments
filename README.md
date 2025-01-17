Testing Heaps
================

This is a test project in which I learn and experiment with Haxe and Heaps.IO.

Troubleshooting notes
------------------------

### Run in Firefox?

I didn't have Chrome installed so I installed VSCode's Firefox debugging extension, then replace `chrome` with `firefox` in the launch task.
Launching works, but the debugger spins forever, never attaching. Launching again does not work.
So I installed Chrome, which worked.

### HashLink

When using latest Heaps (from Git), compiling fails when targetting HashLink because of usages of `format.hl.Native`.
Heaps.IO automatically installs the `format` library, but isn't targetting a recent enough version.
Remove it and install the latest:
```
haxelib remove format
haxelib git format https://github.com/HaxeFoundation/format master
```

### Auto-formatting

Format on save is my daily go-to, except sometimes I want to not format stuff like lookup tables.
Use `// @formatter:off`.
Info about the code formatter: https://github.com/HaxeCheckstyle/haxe-formatter/blob/master/README.md

### Weird Heaps permanent breakage

At some point a weird error started permanently occurring in Heaps, `Recursive array set method `, in several places that were doing array access. No idea what this was about or how it sneaked in, but it kept happening even with an empty Main.

Assumption: maybe I accidentally modified one of the Heaps files, since I regularly open them to inspect how they are written?

Fixed by re-installing Heaps.

### Nitpicks

#### Arrays

In Haxe, arrays are not bound checked. When reading, they either return null, or something unspecified. And upon write, they even resize to fit. This is very different to safety approaches I used in other typed languages. It seems that it could be a source of bugs.

#### Value types

Haxe seems to only have classes for structured data, which are heap-allocated. And like in Java or Javascript, that means all abstraction we can usually build with value-type vector math trigger allocations and garbage collection (in particular code running every frame, mesh generation...).
Will need to investigate how people deal with this. 
