Notes
===============================================

List of all the notes from changes that I spend time on with this tool
I didn't have this "journal" previously, but figured now is as good of
a time to start as any.

November 11th, 2025
---------------------------------------------

Neovim version 0.11.5

Moving to Neovim 11, there are some changes that are needed in lua
for the lsp support, this triggered a number of updates.

The buildVimPlugins function from the nixpkgs is great.  There
are many plugins that run "checks" to make sure that all the lua
modules that are required can be found.  This causes problems
if there is an order for another package as they don't have a
flow of installing all packages before running any checks.  To
resolve this there is the `dependencies` section in the function
where you can pass other packages to the list.

*NOTE:* With the current implementation I don't have an easy way
to have a build in a given area and then have it easily shared
with others as a dependency, this can be adjusted in a future
version, but for this specific build I was able to work successfully
with the builtin vimPlugins for most that I was building.

Also discovered that `whichkey` has a strong dependency on `lazy`
being installed.  I am not using that for my package manager, but
I need to see what other benefits/flows may come from using it that
could be useful.

November 15th, 2025
-------------------------------------------------------------------

At this point I was trying to look at options to resolve the failing
lua builds.  At that time I discovered that there is a better way
to create the neovim package instead of just overriding the package
and that is to use the `pkgs.neovimUtils.makeNeovimConfig` function
from `nixpkgs`.

This gives the option of "skipping" modules with the `nvimSkipModules`
that can specify the modoules.
