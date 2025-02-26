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

### Value types

Haxe seems to only have classes for structured data, which are heap-allocated. That means all abstraction we can usually build with value-types such as vector math triggers allocations and garbage collection (in particular code running every frame, mesh generation...).
Some ideas:
- "Flatten" fields within objects they are used in
- "Flatten" fields if used in arrays, for example a large array of 3D points could be an array of `Float` which has better chances of being packed (or use dedicated containers when available)
- Use target-specific features, like `@:struct` on HashLink and C# (why the doc doesn't say C++?)
- Use `inline` so the compiler gets a chance to elide temporary objects if they don't escape function scope

### Arrays

In Haxe, arrays are not bound checked. When reading, they either return null, or something unspecified. And upon write, they even resize to fit. This is very different to safety approaches I used in other typed languages. It seems that it could be a source of bugs.

