**NOTE**: This is a beta! Some cursors need to be touched up or redrawn, and the hotspots also need to be checked.


# MouseCursorPack

![mouse_cursor_pack_banner](https://user-images.githubusercontent.com/23288188/179344010-81e65575-7c4f-4348-8462-37c217b2e422.png)


This is a set of mouse cursors that can be used with the [LÖVE Framework](https://love2d.org).


## Aren't the system cursors good enough?

On the whole, yes, they are fine. CursorPack was started for a few reasons:

1) On Linux, if you mix custom cursors with system cursors, they are not guaranteed to be of the same scale.

2) On some platforms, certain system cursors obtained with [`love.mouse.getSystemCursor()`](https://love2d.org/wiki/love.mouse.getSystemCursor) are duplicates. For example, on my system, the diagonal size-arrow cursors are duplicates of sizeall.

3) A desire to have paint and adventure game-style cursors handy for future projects.

All cursors in this pack are [CC0](https://creativecommons.org/publicdomain/zero/1.0/), and can be used as the basis for new custom cursors.


## Structure

This repo contains both the finalized cursors, and work versions that can be exported with a script. The final art can be found in the `cursors` directory, arranged into subfolders by size class, and then broad category:

* **system**: Covers the system cursors you can get through `love.mouse.getSystemCursor()`. Can be used to implement fallback texture-based cursors.

* **system_alternatives**: Some variations on the cursors in `system`.

* **auxiliary_pointers**: Alternative pointer cursors which don't have `waitarrow` variations.

* **paint**: Intended for paint applications.

* **senses**: Body parts associated with external human senses.

* **object_metaphors**: Objects that can represent UI actions.


`wip-raster` and `wip-vector` contain *work* versions of the cursors. The raster images don't have transparency set, and the vector images are in SVG format. The `build_cursor_pack.lua` script is used to finalize and export images to the `cursors` folder.

If you're not interested in (re)exporting cursors, you can safely delete `wip-raster`, `wip-svg`, and `build_cursor_pack.lua`.


## Cursor format

By default, all cursors are black-and-white PNGs, with click hotspots encoded in their filenames:

`cursor_name-hx_1_hy_0.png`

Each filename contains one hyphen which separates the cursor ID from its metadata tags.

The tags are:

* `hx_<n>`: Hotspot X position

* `hy_<n>`: Hotspot Y position


The 8x8, 12x12, 16x16, 24x24 and 32x32 cursors are hand-pixeled with cut-out alpha transparency and rough edges. Everything larger than that is exported from SVG (vector) art, with smooth edges.


## test\_cursors.lua

This is a LÖVE application / script which can load all cursors. To run, you need to have LÖVE installed and available in your CLI path. Then invoke: `love . test_cursors`

`test_cursors.lua` is still a bit fragile, and can't deal with PNGs missing within a given size class.


## Notes

The 8x8 and 12x12 cursors are mostly useless on modern desktops. They are included because they might be useful in niche / retro cases.

The SVG cursor art is drawn in Inkscape with a page size of 64x64 pixels, using rescaled versions of the 32x32 raster art as a starting point. Most lines are set to a width of 2 pixels. This is the first real SVG art I've ever done, and I am likely doing some things that aren't quite right.

Some vector objects are not quite full black-and-white. (I'm having some issues with the 'value' slider in Inkscape.)


### Baking assets

Inkscape can convert SVG to PNG from the terminal:

`inkscape -w 64 -h 64 cool_cursor.svg -o cool_cursor.png`

`build_cursor_pack.lua` will export the contents of `wip-raster` and `wip-vector` to the `cursors` folder. (Inkscape is used for the vector export, so it must be installed and accessible from the CLI as `inkscape` for that part to work.) It's currently a pretty hacky solution, and I have only successfully run it on Fedora 36 so far.

The builder script can export with hotspot details encoded within the filename, or create a secondary `.hotspot` file with the offsets.

The SVG images in `wip-vector` must have hotspot positions encoded within their filenames in the range of 0 to 63. This is multiplied and floored when `build_cursor_pack.lua` exports them to PNG.


### Problems

As of July 2022, none of these cursors have been tested in any real applications. If you encounter any issues, feel free to contact me or open an issue ticket.


### Libraries

* `build_cursor_pack.lua`:
  * [NativeFS](https://github.com/EngineerSmith/nativefs)


## License

The sample program and `build_cursor_pack.lua` are MIT. The cursors are [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

MIT License

Copyright (c) 2022 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
