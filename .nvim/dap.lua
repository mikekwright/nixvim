return function(ctx)
  local dap = ctx.dap
  local root = ctx.root

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Python sample: run",
      program = root .. "/samples/python/poetry-demo/main.py",
      cwd = root .. "/samples/python/poetry-demo",
      console = "integratedTerminal",
      justMyCode = false,
      noDebug = true,
    },
    {
      type = "python",
      request = "launch",
      name = "Python sample: debug",
      program = root .. "/samples/python/poetry-demo/main.py",
      cwd = root .. "/samples/python/poetry-demo",
      console = "integratedTerminal",
      justMyCode = false,
    },
  }

  dap.configurations.go = {
    {
      type = "go",
      request = "launch",
      name = "Go sample: run",
      program = root .. "/samples/golang/main.go",
      cwd = root .. "/samples/golang",
      console = "integratedTerminal",
      noDebug = true,
    },
    {
      type = "go",
      request = "launch",
      name = "Go sample: debug",
      program = root .. "/samples/golang/main.go",
      cwd = root .. "/samples/golang",
      console = "integratedTerminal",
    },
  }

  dap.configurations.rust = {
    {
      type = "codelldb",
      request = "launch",
      name = "Rust sample: run",
      program = root .. "/samples/rust/target/debug/rust",
      cwd = root .. "/samples/rust",
      runInTerminal = true,
      noDebug = true,
    },
    {
      type = "codelldb",
      request = "launch",
      name = "Rust sample: debug",
      program = root .. "/samples/rust/target/debug/rust",
      cwd = root .. "/samples/rust",
      runInTerminal = true,
    },
  }

  local javascript_configurations = {
    {
      type = "pwa-node",
      request = "launch",
      name = "JavaScript sample: run",
      program = root .. "/samples/javascript/src/index.js",
      cwd = root .. "/samples/javascript",
      console = "integratedTerminal",
      noDebug = true,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "JavaScript sample: debug",
      program = root .. "/samples/javascript/src/index.js",
      cwd = root .. "/samples/javascript",
      console = "integratedTerminal",
    },
  }
  dap.configurations.javascript = javascript_configurations
  dap.configurations.javascriptreact = javascript_configurations

  local typescript_configurations = {
    {
      type = "pwa-node",
      request = "launch",
      name = "TypeScript sample: run",
      cwd = root .. "/samples/typescript",
      runtimeExecutable = "npm",
      runtimeArgs = { "run", "start" },
      console = "integratedTerminal",
      sourceMaps = true,
      outFiles = { root .. "/samples/typescript/dist/**/*.js" },
      noDebug = true,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "TypeScript sample: debug",
      cwd = root .. "/samples/typescript",
      runtimeExecutable = "npm",
      runtimeArgs = { "run", "debug" },
      console = "integratedTerminal",
      sourceMaps = true,
      outFiles = { root .. "/samples/typescript/dist/**/*.js" },
    },
  }
  dap.configurations.typescript = typescript_configurations
  dap.configurations.typescriptreact = typescript_configurations

  dap.configurations.kotlin = {
    {
      type = "java",
      request = "launch",
      name = "Kotlin sample: run",
      mainClass = "org.example.app.AppKt",
      projectName = "app",
      cwd = root .. "/samples/kotlin",
      console = "integratedTerminal",
      noDebug = true,
    },
    {
      type = "java",
      request = "launch",
      name = "Kotlin sample: debug",
      mainClass = "org.example.app.AppKt",
      projectName = "app",
      cwd = root .. "/samples/kotlin",
      console = "integratedTerminal",
    },
  }

  dap.adapters.haskell = dap.adapters.haskell or {
    type = "executable",
    command = "haskell-debug-adapter",
  }
  dap.configurations.haskell = {
    {
      type = "haskell",
      request = "launch",
      name = "Haskell sample: run",
      workspace = root .. "/samples/haskell",
      startup = root .. "/samples/haskell/hello.hs",
      terminal = "integrated",
      stopOnEntry = false,
      noDebug = true,
    },
    {
      type = "haskell",
      request = "launch",
      name = "Haskell sample: debug",
      workspace = root .. "/samples/haskell",
      startup = root .. "/samples/haskell/hello.hs",
      terminal = "integrated",
      stopOnEntry = false,
    },
  }

  dap.configurations.elixir = {
    {
      type = "mix_task",
      request = "launch",
      name = "Elixir sample: run",
      task = "test",
      projectDir = root .. "/samples/elixir",
      console = "integratedTerminal",
      noDebug = true,
    },
    {
      type = "mix_task",
      request = "launch",
      name = "Elixir sample: debug",
      task = "test",
      projectDir = root .. "/samples/elixir",
      console = "integratedTerminal",
    },
  }

  dap.configurations.erlang = {
    {
      type = "erlang",
      request = "launch",
      name = "Erlang sample: run",
      cwd = root .. "/samples/erlang",
      program = root .. "/samples/erlang/_build/default/lib/sample_app/ebin/sample_app.beam",
      console = "integratedTerminal",
      noDebug = true,
    },
    {
      type = "erlang",
      request = "launch",
      name = "Erlang sample: debug",
      cwd = root .. "/samples/erlang",
      program = root .. "/samples/erlang/_build/default/lib/sample_app/ebin/sample_app.beam",
      console = "integratedTerminal",
    },
  }

  dap.configurations.d = {
    {
      type = "lldb",
      request = "launch",
      name = "D sample: run",
      program = root .. "/samples/dlang/dlang",
      cwd = root .. "/samples/dlang",
      runInTerminal = true,
      stopOnEntry = false,
      noDebug = true,
    },
    {
      type = "lldb",
      request = "launch",
      name = "D sample: debug",
      program = root .. "/samples/dlang/dlang",
      cwd = root .. "/samples/dlang",
      runInTerminal = true,
      stopOnEntry = false,
    },
  }

  dap.configurations.zig = {
    {
      type = "zig",
      request = "launch",
      name = "Zig sample: run",
      program = root .. "/samples/zig/zig-out/bin/zig",
      cwd = root .. "/samples/zig",
      runInTerminal = true,
      stopOnEntry = false,
      noDebug = true,
    },
    {
      type = "zig",
      request = "launch",
      name = "Zig sample: debug",
      program = root .. "/samples/zig/zig-out/bin/zig",
      cwd = root .. "/samples/zig",
      runInTerminal = true,
      stopOnEntry = false,
    },
  }
end
