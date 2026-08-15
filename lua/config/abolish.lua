-- vim-abolish: no setup() required; configuration via global vars if needed.
--
-- Coercion keys (target casing style):
--   Normal mode (single cursor + vim-visual-multi cursor mode): `cr<key>`
--     vim-visual-multi special-cases `cr` (cursors.vim:201) and replays it
--     across all cursors via run_normal — this needs the default `cr` mapping
--     to exist, so we do NOT set abolish_no_mappings.
--   Visual mode (regular, non-VM): `<leader>cr<key>` — `cr` would collide with
--     the built-in `c` (change) operator in visual mode, so use a leader prefix.
--
--   c          camelCase        foo_bar -> fooBar
--   p / m      PascalCase       foo_bar -> FooBar
--   s / _      snake_case       fooBar  -> foo_bar
--   u / U      UPPER_SNAKE      fooBar  -> FOO_BAR
--   - / k      kebab-case       fooBar  -> foo-bar
--   .          dot.case         fooBar  -> foo.bar
--   <space>    space case       fooBar  -> foo bar
--   t          Title Case       foo_bar -> Foo Bar  (custom, see below)

-- Add a custom Title Case coercion (`t`) — vim-abolish ships no `t` by default.
-- snake_case -> space case -> Title Case: foo_bar -> "Foo Bar"
vim.cmd([[
function! AbolishTitleCase(word) abort
  let l:space = substitute(a:word, '_', ' ', 'g')
  return substitute(l:space, '\<\(\a\)\(\a*\)', '\u\1\L\2', 'g')
endfunction
let g:Abolish.Coercions.t = function('AbolishTitleCase')
]])

-- Visual-mode mapping: re-use the plugin's <Plug>(abolish-coerce) under a
-- leader prefix so it doesn't collide with the `c` (change) operator.
vim.keymap.set("v", "<leader>cr", "<Plug>(abolish-coerce)", { desc = "Abolish coerce (visual)" })
