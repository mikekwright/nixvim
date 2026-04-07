{ pkgs, ... }:
let
  name = "lsp.kotlin";

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
              id = 'kotlin',
              label = 'Kotlin',
          filetypes = { 'kotlin' },
              root_markers = { 'build.gradle', 'build.gradle.kts', 'settings.gradle.kts', 'pom.xml' },
              launch_types = { 'kotlin', 'java' },
          guidance = table.concat({
            'Kotlin debugging:',
            '  - Kotlin usually uses a JVM debug adapter and a Gradle or Maven project entrypoint.',
            '  - Use <leader>dC to create project-local .nvim/dap.lua and build before launch.',
            '  - Build or import the project first so the runtime classpath and main class are known.',
          }, '\n'),
          templates = {
            ['dap.lua'] = [=[return function(ctx)
              local dap = ctx.dap
              local root = ctx.root
              local project_dir = root
              local project_name = "Kotlin main class"

              local function build_project()
                local command = vim.uv.fs_stat(project_dir .. "/gradlew") and { "./gradlew", "classes" } or { "gradle", "classes" }
                vim.notify("Building " .. project_name .. "...")
                local result = vim.system(command, { cwd = project_dir, text = true }):wait()
                if result.code ~= 0 then
                  error(table.concat(command, " ") .. " failed:\n" .. (result.stderr or result.stdout or ""))
                end
              end

              dap.configurations.kotlin = {
                {
                  type = "java",
                  request = "launch",
                  name = project_name,
                  cwd = project_dir,
                  mainClass = function()
                    build_project()
                    return "MainKt"
                  end,
                  projectName = vim.fn.fnamemodify(project_dir, ':t'),
                  console = "integratedTerminal",
                },
              }
            end
            ]=],
          },
        })

            vim.lsp.config('kotlin_language_server', {
              cmd = { "${pkgs.kotlin-language-server}/bin/kotlin-language-server" },
          filetypes = { "kotlin" },
            })
            vim.lsp.enable('kotlin_language_server')
  '';
in
{
  inherit lua name;

  packages = with pkgs; [
    kotlin-language-server

    zulu
    kotlin
    #  This doesn't exist for the arm linux
    # kotlin-native

    ktlint
    ktfmt

    gradle
    maven
  ];
}
