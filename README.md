# Simple Image Slideshow
My attempt to experiment with zig and raylib. The "Features" include:
1. flip through images with arrow keys
2. automatic mode with 3second delay
3. zoom and move picture
4. right click to view file in file manager (explorer.exe for windows
   and thunar for linux)

# Usage
After getting an executable (see below how to)
`simpleImageSlideshow.exe` put it in the directory and double click it
to start viewing the files. It is also possible to use from command
line by `.\simpleImageSlideshow.exe <DirectoryPath>`.

# Installation
I used zig version `0.12.0-dev.1396+f6de3ec96` but version 0.11 should
work too. 
## Getting Raylib
On way is to use `zig fetch`, another is installing raylib on your
system and link to it in `build.zin` and the third option is Download
raylib. I explain the third option but there are config functions in
`build.zig` for the others.

To get Raylib, download the source to `./raylib-c` folder relative to
the project root directory, only the `src` folder it needed, and run `zig build`. An
executable should be appear in `zig-out/bin`.

# Motivation
Exploring raylib and zig with hotreloading and build.zig. `raylib-c`
contains source files of raylib with small modification of
`raylib-c/src/build.zig` to export shared library instead of static
one. There is also the option of using build.zig.zon by:
1. `zig fetch --save=raylib
   https://github.com/raysan5/raylib/archive/<hash>.tar.gz` and
   replace with appropriate hash
2. add the following to `build.zig`:

``` zig
const raylib_dep = b.dependency("raylib", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(raylib_dep.artifact("raylib"));
```

# License
src folder under [Apache v2
license](https://www.apache.org/licenses/LICENSE-2.0.html),
[raylib](https://github.com/raysan5/raylib/tree/master) is under the
original license ([zlib](https://github.com/raysan5/raylib/tree/master?tab=Zlib-1-ov-file#readme))
