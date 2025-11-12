{ ... }:

{
  config = /*lua*/ ''
    {
      notify = true, -- show notification on open
      -- Handler to open the url in a browser
      ---@param url string
      open = function(url)
        if vim.fn.has("nvim-0.10") == 0 then
          require("lazy.util").open(url, { system = true })
          return
        end
        vim.ui.open(url)
      end,
      ---@type "repo" | "branch" | "file" | "commit" | "permalink"
      what = "commit", -- what to open. not all remotes support all types
      branch = nil, ---@type string?
      line_start = nil, ---@type number?
      line_end = nil, ---@type number?
      -- patterns to transform remotes to an actual URL
      remote_patterns = {
        { "^(https?://.*)%.git$"              , "%1" },
        { "^git@(.+):(.+)%.git$"              , "https://%1/%2" },
        { "^git@(.+):(.+)$"                   , "https://%1/%2" },
        { "^git@(.+)/(.+)$"                   , "https://%1/%2" },
        { "^ssh://git@(.*)$"                  , "https://%1" },
        { "^ssh://([^:/]+)(:%d+)/(.*)$"       , "https://%1/%3" },
        { "^ssh://([^/]+)/(.*)$"              , "https://%1/%2" },
        { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
        { "^https://%w*@(.*)"                 , "https://%1" },
        { "^git@(.*)"                         , "https://%1" },
        { ":%d+"                              , "" },
        { "%.git$"                            , "" },
      },
      url_patterns = {
        ["github%.com"] = {
          branch = "/tree/{branch}",
          file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
          permalink = "/blob/{commit}/{file}#L{line_start}-L{line_end}",
          commit = "/commit/{commit}",
        },
        ["gitlab%.com"] = {
          branch = "/-/tree/{branch}",
          file = "/-/blob/{branch}/{file}#L{line_start}-L{line_end}",
          permalink = "/-/blob/{commit}/{file}#L{line_start}-L{line_end}",
          commit = "/-/commit/{commit}",
        },
        ["bitbucket%.org"] = {
          branch = "/src/{branch}",
          file = "/src/{branch}/{file}#lines-{line_start}-L{line_end}",
          permalink = "/src/{commit}/{file}#lines-{line_start}-L{line_end}",
          commit = "/commits/{commit}",
        },
      },
    }
  '';

  keymaps = /*lua*/ ''
    -- Gitbrowse file view
    keymapd("<leader>egg", "View the file in github", function()
      snacks.gitbrowse()
    end)
    keymapd("<leader>egb", "Blame view current line", function()
      snacks.git.blame_line()
    end)
  '';
}
