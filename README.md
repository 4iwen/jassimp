# jassimp

Jai bindings for the C API of [Assimp](https://github.com/assimp/assimp) `v6.0.2`.

The repository ships generated bindings for Windows and macOS.

On Windows, `jai generate.jai` builds a static Assimp + zlib pair into
`bindings/windows/x64/` and regenerates `bindings/windows/windows.jai`.
This requires the `assimp/` submodule to be present.

On macOS, `jai generate.jai` regenerates the bindings against the checked-in
static libraries in `bindings/macos/arm64/`.

To use, import this package and link the generated static libraries from the
bindings directory selected by your platform.
