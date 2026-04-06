{ pkgs, ... }:

let
  name = "lsp.erlang";

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
              id = 'erlang',
              label = 'Erlang',
          filetypes = { 'erlang' },
              root_markers = { 'rebar.config', 'erlang.mk' },
              launch_types = { 'erlang' },
          guidance = table.concat({
            'Erlang debugging:',
            '  - Erlang debugging is adapter-specific and usually tied to your rebar or runtime setup.',
            '  - Use <leader>dC to create project-local .nvim/dap.lua and point it at your Erlang debug adapter.',
            '  - Start from the project root so rebar.config and compiled beams are available.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
          local dap = ctx.dap
          local root = ctx.root

          dap.configurations.erlang = {
            {
              type = "erlang",
              request = "launch",
              name = "Erlang node",
              cwd = root,
              program = root .. "/_build/default/rel/app/bin/app",
          console = "integratedTerminal",
        },
      }
    end
    ]=],
          },
        })

            vim.lsp.config('elp', {
              cmd = { "${pkgs.erlang-language-platform}/bin/elp", "server" },
            })
            vim.lsp.enable('elp')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    erlang-language-platform
    erlang
  ];
}
