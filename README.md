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

* [Learn Lua X in Y minutes](https://learnxinyminutes.com/docs/lua/)

* [Neovim Documentation](https://neovim.io/doc/user/builtin.html)

* [Youtube - Setting up Neovim from scratch with tmux](https://www.youtube.com/watch?v=ZjMzBd1Dqz8)
* [Github - Nixvim Repo](https://github.com/nix-community/nixvim/blob/main/plugins/filetrees/nvim-tree.nix)
* [Github - Nvim-tree repo](https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt)
* [Github - Strong nixvim flake example](https://github.com/pete3n/nixvim-flake)
* [Article - Nixvim with home manager and custom vim plugin](https://valentinpratz.de/posts/2024-02-12-nixvim-home-manager/)
* [Youtube - Simple series on configuring Neovim](https://www.youtube.com/watch?v=zHTeCSVAFNY)
* [Github - Another nvim example](https://github.com/elythh/nixvim)

## TODOs

* Install [Statuscol which gives a left side status column](https://github.com/luukvbaal/statuscol.nvim)
* Look at [Nightfly color scheme](https://github.com/bluz71/vim-nightfly-colors)
* Install [k8s support](https://github.com/Ramilito/kubectl.nvim)
* Decide [Should I use the auto-session (project kind of)](https://github.com/rmagatti/auto-session)
* Look at [Surround that helps surround text](https://github.com/kylechui/nvim-surround)
* Try out COC [Conquer of Completion](https://github.com/neoclide/coc.nvim)
* Can also see [Jira plugin for neovim](https://github.com/Arekkusuva/jira-nvim)
