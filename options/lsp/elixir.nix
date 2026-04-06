{ pkgs, ... }:

let
  name = "lsp.elixir";

  lua = /* lua */ ''
            local register_debug_language = _G.register_debug_language or function(spec)
              if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
                return
              end

              _G.debug_language_registry = _G.debug_language_registry or {}
              _G.debug_filetype_registry = _G.debug_filetype_registry or {}
              _G.debug_language_registry[spec.id] = spec

              for _, filetype in ipairs(spec.filetypes or {}) do
                _G.debug_filetype_registry[filetype] = spec.id
              end
            end

            register_debug_language({
              id = 'elixir',
              label = 'Elixir',
              filetypes = { 'elixir', 'eelixir', 'heex' },
              root_markers = { 'mix.exs' },
              launch_types = { 'mix_task', 'elixir' },
          guidance = table.concat({
            'Elixir debugging:',
            '  - Elixir debugging depends on a project-specific BEAM debug adapter setup.',
            '  - Use <leader>dC to create project-local .nvim/dap.lua and point it at your Elixir adapter or task entrypoint.',
            '  - Start from the Mix project root so mix.exs and your runtime environment are available.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
          local dap = ctx.dap
          local root = ctx.root

          dap.configurations.elixir = {
            {
              type = "mix_task",
              request = "launch",
              name = "Mix task",
              task = "phx.server",
              projectDir = root,
          console = "integratedTerminal",
        },
      }
    end
    ]=],
          },
        })

            vim.lsp.config('elixirls', {
              cmd = { "${pkgs.elixir-ls}/bin/elixir-ls" },
            })
            vim.lsp.enable('elixirls')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    elixir-ls
    elixir
  ];
}
