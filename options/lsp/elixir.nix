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
        '  - Use <leader>dC to create project-local .nvim/dap.lua and compile with Mix before launch.',
        '  - Start from the Mix project root so mix.exs and your runtime environment are available.',
      }, '\n'),
      templates = {
        ['dap.lua'] = [=[return function(ctx)
          local dap = ctx.dap
          local root = ctx.root
          local project_dir = root
          local project_name = "Mix task"

          local function build_project()
            vim.notify("Compiling " .. project_name .. "...")
            local result = vim.system(
              { "mix", "compile" },
              { cwd = project_dir, text = true }
            ):wait()

            if result.code ~= 0 then
              error("mix compile failed:\n" .. (result.stderr or result.stdout or ""))
            end
          end

          dap.configurations.elixir = {
            {
              type = "mix_task",
              request = "launch",
              name = project_name,
              task = function()
                build_project()
                return "phx.server"
              end,
              projectDir = project_dir,
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
