-- CODE VERIFIED (bash scripts/check.sh: 18 passed; E45 + snacks-notify + modified-buffer paths exercised)
-- Write audit log — for diagnosing "write error on quit" and "couldn't exit".
--
-- Records ONLY:
--   * the :messages delta and v:errmsg
--   * snacks.notifier history at WARN+  (snacks replaces vim.notify, so those
--     notifications never reach :messages — see notes below)
--   * buffer *metadata*: name, modified, readonly, buftype, filetype
--   * on quit: names of *other* buffers that would block :q (E37 / E162)
--
-- It never reads buffer contents, registers, marks, jump list or undo data, so
-- source code cannot leak into the log. Every line is ANSI-stripped, flattened
-- to one line and truncated to MAX_LINE. Log files are chmod 0600.
--
-- Logs: $XDG_STATE_HOME/nvim/write-audit/YYYY-MM-DD.log   ->  :WriteAudit
-- Test override: WRITE_AUDIT_DIR=/tmp/x nvim ...

local M = {}

local MAX_LINE = 400
local MAX_BYTES = 2 * 1024 * 1024 -- rotate to <file>.1 above this
local MAX_BURST = 200             -- max message lines recorded per event
local LEVELS = { 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'OFF' }
local WARN = vim.log.levels.WARN or 3

local dir = vim.env.WRITE_AUDIT_DIR or (vim.fn.stdpath('state') .. '/write-audit')

local last_messages = {}
local last_errmsg = ''
local last_notif_added = 0

local function sanitize(s)
  s = tostring(s or ''):gsub('\27%[[%d;]*m', '') -- strip ANSI
  s = s:gsub('[\r\n]+', ' ')
  if #s > MAX_LINE then
    s = s:sub(1, MAX_LINE) .. '…'
  end
  return s
end

local function level_num(l)
  if type(l) == 'number' then
    return l
  end
  if type(l) == 'string' then
    return vim.log.levels[l:upper()] or WARN
  end
  return WARN
end

local function log_path()
  return dir .. '/' .. os.date('%Y-%m-%d') .. '.log'
end

local function append(lines)
  if #lines == 0 then
    return
  end
  pcall(function()
    vim.fn.mkdir(dir, 'p')
    local path = log_path()
    local stat = vim.uv.fs_stat(path)
    if stat and stat.size > MAX_BYTES then
      os.remove(path .. '.1')
      os.rename(path, path .. '.1')
      stat = nil
    end
    vim.fn.writefile(lines, path, 'a')
    if not stat then
      vim.uv.fs_chmod(path, 384) -- 0600, first creation only
    end
  end)
end

-- Longest suffix of the previously recorded :messages that is a prefix of the
-- current one, so only new lines are appended (handles history overflow).
local function message_delta()
  local ok, res = pcall(vim.api.nvim_exec2, 'silent messages', { output = true })
  if not ok or type(res) ~= 'table' then
    return {}
  end
  local all = vim.split(res.output or '', '\n', { plain = true })
  while #all > 0 and all[#all] == '' do
    table.remove(all)
  end

  local start = 1
  for i = #last_messages, 1, -1 do
    local n = #last_messages - i + 1
    local same = true
    for k = 1, n do
      if last_messages[i + k - 1] ~= all[k] then
        same = false
        break
      end
    end
    if same then
      start = n + 1
      break
    end
  end

  local out = {}
  for i = start, #all do
    out[#out + 1] = sanitize(all[i])
  end
  if #out > MAX_BURST then
    local tail = { ('... %d earlier message lines omitted'):format(#out - MAX_BURST) }
    for i = #out - MAX_BURST + 1, #out do
      tail[#tail + 1] = out[i]
    end
    out = tail
  end
  last_messages = all
  return out
end

-- snacks.notifier takes over vim.notify, so plugin/formatter/LSP warnings raised
-- through vim.notify are NOT in :messages. Pull them from its history instead.
local function notifier_delta()
  local ok, notifier = pcall(require, 'snacks.notifier')
  if not ok or type(notifier) ~= 'table' then
    return {}
  end
  local ok2, hist = pcall(notifier.get_history, { filter = WARN })
  if not ok2 or type(hist) ~= 'table' then
    return {}
  end

  local out = {}
  for _, n in ipairs(hist) do
    local added = tonumber(n.added) or 0
    if added > last_notif_added then
      local title = (type(n.title) == 'string' and n.title ~= '') and (n.title .. ': ') or ''
      out[#out + 1] = sanitize(LEVELS[level_num(n.level) + 1] .. ' ' .. title .. tostring(n.msg or ''))
      last_notif_added = math.max(last_notif_added, added)
    end
  end
  return out
end

local function record(event)
  pcall(function()
    local buf = vim.api.nvim_get_current_buf()
    local bo = vim.bo[buf]
    local name = vim.api.nvim_buf_get_name(buf)
    local out = {
      ('%s  %-10s %s  modified=%s readonly=%s buftype=%s ft=%s'):format(
        os.date('%Y-%m-%d %H:%M:%S'),
        event,
        sanitize(name ~= '' and name or '[No Name]'),
        tostring(bo.modified),
        tostring(bo.readonly),
        bo.buftype ~= '' and bo.buftype or '-',
        bo.filetype ~= '' and bo.filetype or '-'
      ),
    }

    local errmsg = sanitize(vim.v.errmsg)
    if errmsg ~= '' and errmsg ~= last_errmsg then
      out[#out + 1] = '  v:errmsg: ' .. errmsg
    end
    last_errmsg = errmsg

    for _, line in ipairs(message_delta()) do
      out[#out + 1] = '  msg: ' .. line
    end
    for _, line in ipairs(notifier_delta()) do
      out[#out + 1] = '  notify: ' .. line
    end

    -- The usual reason a quit is refused: some other buffer is still modified.
    if event == 'quit-pre' or event == 'leave-pre' then
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= buf and vim.api.nvim_buf_is_valid(b) and vim.bo[b].modified then
          out[#out + 1] = '  modified-buffer: ' .. sanitize(vim.api.nvim_buf_get_name(b))
        end
      end
    end

    append(out)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup('WriteAudit', { clear = true })

  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    pattern = '*',
    desc = 'audit: buffer state before write',
    callback = function()
      record('write-pre')
    end,
  })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*',
    desc = 'audit: messages + state after write',
    callback = function()
      record('write-post')
    end,
  })
  vim.api.nvim_create_autocmd('QuitPre', {
    group = group,
    desc = 'audit: why a quit may be refused',
    callback = function()
      record('quit-pre')
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    desc = 'audit: final messages before exit',
    callback = function()
      record('leave-pre')
    end,
  })

  vim.api.nvim_create_user_command('WriteAudit', function()
    local path = log_path()
    if vim.uv.fs_stat(path) == nil then
      vim.notify('No write-audit log for ' .. os.date('%Y-%m-%d') .. ' yet (' .. dir .. ')', vim.log.levels.INFO)
      return
    end
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  end, { desc = 'Open the write audit log' })

  vim.api.nvim_create_user_command('WriteAuditDir', function()
    vim.notify(dir, vim.log.levels.INFO)
  end, { desc = 'Show the write audit log directory' })
end

return M
