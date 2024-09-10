# Neovim config in nix

Starting on this template to get my neovim configuration working with nix.

This template gives you a good starting point and hopefully a more lua driven
and simple/clear process for working with neovim.

## Configuring

To start configuring, just add or modify the nix files in `./config`.
If you add a new configuration file, remember to add it to the
[`config/default.nix`](./config/default.nix) file

## Testing your new configuration

To test your configuration simply run the following command

```bash
nix run .
```

## References

* [Neovim Documentation](https://neovim.io/doc/user/builtin.html)

* [Youtube - Setting up Neovim from scratch with tmux](https://www.youtube.com/watch?v=ZjMzBd1Dqz8)
* [Github - Nixvim Repo](https://github.com/nix-community/nixvim/blob/main/plugins/filetrees/nvim-tree.nix)
* [Github - Nvim-tree repo](https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt)
* [Github - Strong nixvim flake example](https://github.com/pete3n/nixvim-flake)
* [Article - Nixvim with home manager and custom vim plugin](https://valentinpratz.de/posts/2024-02-12-nixvim-home-manager/)
* [Youtube - Simple series on configuring Neovim](https://www.youtube.com/watch?v=zHTeCSVAFNY)
* [Github - Another nvim example](https://github.com/elythh/nixvim)
