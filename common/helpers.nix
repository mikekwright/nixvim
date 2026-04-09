{ ... }:

let
  lua = /* lua */ ''
    _G.nixvim_helpers = _G.nixvim_helpers or {}

    local helpers = _G.nixvim_helpers

    helpers.get_buffer_start_path = function(bufnr)
      local buffer_name = bufnr and vim.api.nvim_buf_get_name(bufnr) or ""
      return buffer_name ~= "" and vim.fs.dirname(buffer_name) or vim.uv.cwd()
    end

    helpers.build_cache_key = function(path)
      local stat = vim.uv.fs_stat(path)
      if not stat or not stat.mtime then
        return nil
      end

      return tostring(stat.mtime.sec) .. ':' .. tostring(stat.mtime.nsec or 0)
    end

    helpers.find_nearest_navigating_up = function(bufnr, markers)
      local target_markers = type(markers) == 'table' and markers or { markers }
      return vim.fs.find(target_markers, {
        path = helpers.get_buffer_start_path(bufnr),
        upward = true,
        stop = vim.uv.os_homedir(),
      })[1]
    end

    helpers.find_project_root_from_marker_path = function(path)
      local normalized = vim.fs.normalize(path)

      if normalized:match('/%.git$') then
        return vim.fs.dirname(normalized)
      end

      if normalized:match('/%.nvim/[^/]+$') or normalized:match('/%.vscode/[^/]+$') then
        return vim.fs.dirname(vim.fs.dirname(normalized))
      end

      return vim.fs.dirname(normalized)
    end

    helpers.detect_project_root = function(bufnr, markers)
      local marker = helpers.find_nearest_navigating_up(bufnr, markers)
      if not marker then
        return nil
      end

      return helpers.find_project_root_from_marker_path(marker)
    end

  '';
in
{
  common = true;

  lua = lua;
}
