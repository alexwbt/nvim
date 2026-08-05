-- Visual Studio 2022 (dark) C++ palette, hand-rolled.
-- Loaded via `:colorscheme vs-cpp`. No plugin dependency.

local M = {}

-- Palette (VS 2022 dark C++ defaults).
local C = {
  bg          = "#1E1E1E",
  bg_alt      = "#252526",
  bg_sel      = "#264F78",
  bg_ui       = "#2D2D30",
  border      = "#3F3F46",
  fg          = "#DCDCDC",
  fg_bright   = "#F1F1F1",
  fg_dim      = "#9B9B9B",
  comment     = "#57A64A",
  keyword     = "#569CD6",
  control     = "#C586C0",
  type        = "#4EC9B0",
  func        = "#DCDCAA",
  macro       = "#BEB7FF",
  preproc     = "#9B9B9B",
  string      = "#D69D85",
  number      = "#B5CEA8",
  variable    = "#9CDCFE",
  constant    = "#B5CEA8",
  operator    = "#B4B4B4",
  error       = "#F48771",
  warning     = "#CCA700",
  match       = "#3B3B3B",
  search      = "#5780C0",
}

-- Map a treesitter / lsp highlight group to a {fg,bg,style} spec.
local function hl(name, spec)
  spec = spec or {}
  if spec.link then
    vim.api.nvim_set_hl(0, name, { link = spec.link })
    return
  end
  vim.api.nvim_set_hl(0, name, {
    fg = spec.fg,
    bg = spec.bg,
    sp = spec.sp,
    bold = spec.bold,
    italic = spec.italic,
    underline = spec.underline,
    undercurl = spec.undercurl,
    reverse = spec.reverse,
    nocombine = spec.nocombine,
    strikethrough = spec.strikethrough,
  })
end

function M.load()
  -- Clear existing highlights so we start from a known state.
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  vim.g.colors_name = "vscpp"
  vim.o.termguicolors = true
  vim.o.background = "dark"

  -- Editor chrome.
  hl("Normal",       { fg = C.fg, bg = C.bg })
  hl("NormalNC",     { fg = C.fg, bg = C.bg })
  hl("NormalFloat",  { fg = C.fg, bg = C.bg_ui })
  hl("FloatBorder",  { fg = C.border, bg = C.bg_ui })
  hl("CursorLine",   { bg = C.bg_alt })
  hl("CursorColumn", { bg = C.bg_alt })
  hl("CursorLineNr", { fg = C.fg_bright, bold = true })
  hl("LineNr",       { fg = C.fg_dim })
  hl("SignColumn",   { bg = C.bg })
  hl("VertSplit",    { fg = C.border, bg = C.bg })
  hl("WinSeparator", { fg = C.border, bg = C.bg })
  hl("StatusLine",   { fg = C.fg, bg = C.bg_ui })
  hl("StatusLineNC", { fg = C.fg_dim, bg = C.bg_alt })
  hl("TabLine",      { fg = C.fg_dim, bg = C.bg_alt })
  hl("TabLineSel",   { fg = C.fg_bright, bg = C.bg, bold = true })
  hl("TabLineFill",  { bg = C.bg_ui })
  hl("Pmenu",        { fg = C.fg, bg = C.bg_ui })
  hl("PmenuSel",     { fg = C.fg_bright, bg = C.bg_sel })
  hl("PmenuSbar",    { bg = C.bg_ui })
  hl("PmenuThumb",   { bg = C.border })
  hl("WildMenu",     { fg = C.fg_bright, bg = C.bg_sel })
  hl("Visual",       { bg = C.bg_sel })
  hl("VisualNOS",    { bg = C.bg_sel })
  hl("Search",       { bg = C.search })
  hl("IncSearch",    { bg = C.search })
  hl("MatchParen",   { bg = C.match })
  hl("Conceal",      { fg = C.fg_dim })
  hl("NonText",      { fg = C.border })
  hl("Whitespace",   { fg = C.border })
  hl("SpecialKey",   { fg = C.border })
  hl("Title",        { fg = C.keyword, bold = true })
  hl("Question",     { fg = C.comment })
  hl("MoreMsg",      { fg = C.comment })
  hl("ModeMsg",      { fg = C.fg_dim })
  hl("MsgArea",      { fg = C.fg, bg = C.bg })
  hl("Directory",    { fg = C.keyword })
  hl("EndOfBuffer",  { fg = C.bg })
  hl("QuickFixLine", { bg = C.bg_alt, bold = true })
  hl("ColorColumn",  { bg = C.bg_alt })
  hl("Folded",       { fg = C.fg_dim, bg = C.bg_alt })
  hl("FoldColumn",   { fg = C.fg_dim, bg = C.bg })
  hl("WinBar",       { fg = C.fg, bg = C.bg_alt })
  hl("WinBarNC",     { fg = C.fg_dim, bg = C.bg_alt })

  -- Diagnostics.
  hl("DiagnosticError", { fg = C.error })
  hl("DiagnosticWarn",  { fg = C.warning })
  hl("DiagnosticInfo",  { fg = C.keyword })
  hl("DiagnosticHint",  { fg = C.type })
  hl("DiagnosticUnderlineError", { undercurl = true, sp = C.error })
  hl("DiagnosticUnderlineWarn",  { undercurl = true, sp = C.warning })
  hl("DiagnosticUnderlineInfo",  { undercurl = true, sp = C.keyword })
  hl("DiagnosticUnderlineHint",  { undercurl = true, sp = C.type })

  -- Git / diff.
  hl("DiffAdd",      { bg = "#1F3B1F" })
  hl("DiffChange",   { bg = "#1F2B3B" })
  hl("DiffDelete",   { bg = "#3B1F1F" })
  hl("DiffText",     { bg = "#2F4F2F" })
  hl("GitSignsAdd",    { fg = C.comment })
  hl("GitSignsChange", { fg = C.keyword })
  hl("GitSignsDelete", { fg = C.error })

  -- Spell.
  hl("SpellBad",   { undercurl = true, sp = C.error })
  hl("SpellCap",   { undercurl = true, sp = C.keyword })
  hl("SpellRare",  { undercurl = true, sp = C.type })
  hl("SpellLocal", { undercurl = true, sp = C.warning })

  -- Standard syntax groups (used when treesitter is off).
  hl("Comment",    { fg = C.comment, italic = true })
  hl("Constant",   { fg = C.constant })
  hl("String",     { fg = C.string })
  hl("Character",  { fg = C.string })
  hl("Number",     { fg = C.number })
  hl("Boolean",    { fg = C.number })
  hl("Float",      { fg = C.number })
  hl("Identifier", { fg = C.variable })
  hl("Function",   { fg = C.func })
  hl("Statement",  { fg = C.keyword })
  hl("Conditional", { fg = C.keyword })
  hl("Repeat",      { fg = C.keyword })
  hl("Label",       { fg = C.keyword })
  hl("Operator",    { fg = C.operator })
  hl("Keyword",     { fg = C.keyword })
  hl("Exception",   { fg = C.control })
  hl("PreProc",     { fg = C.preproc })
  hl("Include",     { fg = C.preproc })
  hl("Define",      { fg = C.macro })
  hl("Macro",       { fg = C.macro })
  hl("PreCondit",   { fg = C.preproc })
  hl("Type",        { fg = C.type })
  hl("StorageClass",{ fg = C.keyword })
  hl("Structure",   { fg = C.type })
  hl("Typedef",     { fg = C.type })
  hl("Special",        { fg = C.func })
  hl("SpecialChar",    { fg = C.string })
  hl("Tag",           { fg = C.keyword })
  hl("Delimiter",     { fg = C.operator })
  hl("SpecialComment",{ fg = C.comment, bold = true })
  hl("Debug",         { fg = C.warning })
  hl("Underlined",    { underline = true, fg = C.keyword })
  hl("Ignore",        { fg = C.fg_dim })
  hl("Error",         { fg = C.error, bg = C.bg, bold = true })
  hl("Todo",          { fg = C.warning, bg = C.bg, bold = true })

  -- LSP semantic tokens (used by clangd for C/C++).
  hl("@lsp.type.comment",         { link = "Comment" })
  hl("@lsp.type.keyword",         { fg = C.keyword })
  hl("@lsp.type.controlKeyword",  { fg = C.control })
  hl("@lsp.type.operator",        { link = "Operator" })
  hl("@lsp.type.namespace",       { fg = "#C8C8C8" })
  hl("@lsp.type.type",            { link = "Type" })
  hl("@lsp.type.class",           { fg = C.type })
  hl("@lsp.type.struct",          { fg = C.type })
  hl("@lsp.type.parameter",       { fg = "#9A9A9A" })
  hl("@lsp.type.variable",        { fg = C.variable })
  hl("@lsp.type.property",        { fg = "#CACACA" })
  hl("@lsp.type.function",        { link = "Function" })
  hl("@lsp.type.method",          { link = "Function" })
  hl("@lsp.type.macro",           { fg = C.macro })
  hl("@lsp.type.string",          { link = "String" })
  hl("@lsp.type.number",          { link = "Number" })
  hl("@lsp.type.regexp",          { fg = C.string })
  hl("@lsp.type.decorator",       { fg = C.func })
  hl("@lsp.mod.deprecated",       { fg = C.error, undercurl = true })
  hl("@lsp.mod.static",           {})
  hl("@lsp.typemod.variable.readonly", { fg = "#CACACA" })

  -- Treesitter captures (preferred for C/C++ via nvim-treesitter).
  hl("@comment",          { link = "Comment" })
  hl("@keyword",          { fg = C.keyword })
  hl("@keyword.function", { fg = C.keyword })
  hl("@keyword.operator", { fg = C.keyword })
  hl("@keyword.return",   { fg = C.keyword })
  hl("@conditional",      { fg = C.control })
  hl("@repeat",           { fg = C.keyword })
  hl("@label",            { fg = C.keyword })
  hl("@operator",         { fg = C.operator })
  hl("@exception",        { fg = C.control })
  hl("@type",             { fg = C.type })
  hl("@type.builtin",     { fg = C.type })
  hl("@type.qualifier",   { fg = C.keyword })
  hl("@type.definition",  { fg = C.type })
  hl("@structure",        { fg = C.type })
  hl("@function",         { fg = C.func })
  hl("@function.builtin", { fg = C.func })
  hl("@function.call",    { fg = C.func })
  hl("@function.macro",   { fg = C.macro })
  hl("@method",           { fg = C.func })
  hl("@method.call",      { fg = C.func })
  hl("@constructor",      { fg = C.type })
  hl("@parameter",        { fg = C.variable })
  hl("@variable",         { fg = C.variable })
  hl("@variable.builtin", { fg = C.keyword })
  hl("@variable.member",  { fg = C.variable })
  hl("@constant",         { fg = C.constant })
  hl("@constant.builtin", { fg = C.constant })
  hl("@constant.macro",   { fg = C.macro })
  hl("@string",           { link = "String" })
  hl("@string.escape",    { fg = C.func })
  hl("@string.special",   { fg = C.func })
  hl("@character",        { link = "String" })
  hl("@number",           { link = "Number" })
  hl("@boolean",          { link = "Number" })
  hl("@float",            { link = "Number" })
  hl("@punctuation",      { fg = C.operator })
  hl("@punctuation.bracket", { fg = C.operator })
  hl("@punctuation.delimiter", { fg = C.operator })
  hl("@punctuation.special", { fg = C.func })
  hl("@macro",            { fg = C.macro })
  hl("@preproc",          { fg = C.preproc })
  hl("@define",           { fg = C.macro })
  hl("@include",          { fg = C.preproc })
  hl("@namespace",        { fg = C.type })
  hl("@module",           { fg = C.type })
  hl("@tag",              { fg = C.keyword })
  hl("@tag.attribute",    { fg = C.variable })
  hl("@tag.delimiter",    { fg = C.operator })
  hl("@text.literal",     { fg = C.string })
  hl("@text.reference",   { fg = C.keyword })
  hl("@text.title",       { fg = C.keyword, bold = true })
  hl("@text.uri",         { fg = C.keyword, underline = true })
  hl("@diff.plus",        { fg = C.comment })
  hl("@diff.minus",       { fg = C.error })
  hl("@diff.delta",       { fg = C.keyword })

  -- C/C++ specific treesitter captures.
  hl("@keyword.c",            { fg = C.keyword })
  hl("@keyword.cpp",          { fg = C.keyword })
  hl("@type.c",               { fg = C.type })
  hl("@type.cpp",             { fg = C.type })
  hl("@function.c",           { fg = C.func })
  hl("@function.cpp",         { fg = C.func })
  hl("@variable.c",           { fg = C.variable })
  hl("@variable.cpp",         { fg = C.variable })
  hl("@constant.c",           { fg = C.constant })
  hl("@constant.cpp",         { fg = C.constant })
  hl("@preproc.c",            { fg = C.preproc })
  hl("@preproc.cpp",          { fg = C.preproc })
  hl("@define.c",             { fg = C.macro })
  hl("@define.cpp",           { fg = C.macro })
  hl("@include.c",            { fg = C.preproc })
  hl("@include.cpp",          { fg = C.preproc })

  -- C/C++ regex syntax: built-in types/modifiers = keyword blue.
  hl("cType",          { fg = C.keyword })
  hl("cppType",        { fg = C.keyword })
  hl("cppModifier",    { fg = C.keyword })
  hl("cStatement",     { fg = C.control })

  -- LSP UI highlights.
  hl("LspReferenceText",  { bg = C.match })
  hl("LspReferenceRead",  { bg = C.match })
  hl("LspReferenceWrite", { bg = C.match })
  hl("DiagnosticSignError", { fg = C.error })
  hl("DiagnosticSignWarn",  { fg = C.warning })
  hl("DiagnosticSignInfo",  { fg = C.keyword })
  hl("DiagnosticSignHint",  { fg = C.type })
  hl("DiagnosticFloatingError", { fg = C.error })
  hl("DiagnosticFloatingWarn",  { fg = C.warning })
  hl("LspSignatureActiveParameter", { underline = true, bold = true })
  hl("LspInlayHint", { fg = C.fg_dim, bg = C.bg_alt, italic = true })

  -- Treesitter context / playground.
  hl("TreesitterContext",       { bg = C.bg_alt })
  hl("TreesitterContextBottom", { underline = true, sp = C.border })

  -- Telescope.
  hl("TelescopeNormal",                  { fg = C.fg, bg = C.bg })
  hl("TelescopeBorder",                  { fg = C.border })
  hl("TelescopePromptBorder",            { fg = C.border })
  hl("TelescopeResultsBorder",           { fg = C.border })
  hl("TelescopePreviewBorder",           { fg = C.border })
  hl("TelescopeTitle",                   { fg = C.keyword, bold = true })
  hl("TelescopePromptTitle",             { fg = C.keyword, bold = true })
  hl("TelescopeResultsTitle",            { fg = C.type, bold = true })
  hl("TelescopePreviewTitle",            { fg = C.func, bold = true })
  hl("TelescopeSelection",               { bg = C.bg_sel })
  hl("TelescopeSelectionCaret",          { fg = C.keyword })
  hl("TelescopeMultiSelection",          { bg = C.bg_sel })
  hl("TelescopeMatching",                { fg = C.func })
  hl("TelescopePromptPrefix",            { fg = C.keyword })
  hl("TelescopePreviewLine",             { bg = C.bg_alt })
  hl("TelescopePreviewMatch",            { bg = C.match })
  hl("TelescopePreviewHyphen",           { fg = C.fg_dim })
  hl("TelescopePreviewPipe",             { fg = C.func })
  hl("TelescopePreviewSize",             { fg = C.number })
  hl("TelescopePreviewUser",             { fg = C.type })
  hl("TelescopePreviewGroup",            { fg = C.type })
  hl("TelescopePreviewDate",             { fg = C.fg_dim })
  hl("TelescopePreviewMessage",          { fg = C.fg_dim })
  hl("TelescopeResultsClass",            { fg = C.type })
  hl("TelescopeResultsConstant",         { fg = C.constant })
  hl("TelescopeResultsField",            { fg = C.variable })
  hl("TelescopeResultsFunction",         { fg = C.func })
  hl("TelescopeResultsIdentifier",       { fg = C.variable })
  hl("TelescopeResultsLineNr",           { fg = C.fg_dim })
  hl("TelescopeResultsMethod",           { fg = C.func })
  hl("TelescopeResultsOperator",         { fg = C.operator })
  hl("TelescopeResultsStruct",           { fg = C.type })
  hl("TelescopeResultsVariable",         { fg = C.variable })
  hl("TelescopeResultsSpecialComment",   { fg = C.comment })
  hl("TelescopePathSeparator",           { fg = C.border })
  hl("TelescopePathLink",                { fg = C.keyword })
  hl("TelescopeFuzzyIcon",               { fg = C.func })

  -- Oil.nvim.
  hl("OilDir",     { fg = C.keyword })
  hl("OilDirIcon", { fg = C.keyword })
  hl("OilFile",    { fg = C.fg })
  hl("OilLink",    { fg = C.type })
  hl("OilLinkTarget", { fg = C.fg_dim })
  hl("OilSymlink", { fg = C.type })
  hl("OilSocket",  { fg = C.warning })

  -- Neo-tree.
  hl("NeoTreeNormal",         { fg = C.fg, bg = C.bg })
  hl("NeoTreeNormalNC",       { fg = C.fg, bg = C.bg })
  hl("NeoTreeRootName",       { fg = C.fg_bright, bold = true })
  hl("NeoTreeDirectoryName",  { fg = C.keyword })
  hl("NeoTreeDirectoryIcon",  { fg = C.keyword })
  hl("NeoTreeFileIcon",       { fg = C.fg })
  hl("NeoTreeFileName",       { fg = C.fg })
  hl("NeoTreeFileNameOpened", { fg = C.func })
  hl("NeoTreeGitAdded",       { fg = C.comment })
  hl("NeoTreeGitModified",    { fg = C.keyword })
  hl("NeoTreeGitDeleted",     { fg = C.error })
  hl("NeoTreeGitUntracked",   { fg = C.type })
  hl("NeoTreeGitUnstaged",    { fg = C.warning })
  hl("NeoTreeGitStaged",      { fg = C.comment })
  hl("NeoTreeGitConflict",    { fg = C.error })
  hl("NeoTreeGitIgnored",     { fg = C.fg_dim })
  hl("NeoTreeIndentMarker",   { fg = C.border })
  hl("NeoTreeSymbolicLinkTarget", { fg = C.type })
  hl("NeoTreeTitleBar",       { fg = C.fg_bright, bg = C.bg_ui })
  hl("NeoTreeFloatBorder",    { fg = C.border })
  hl("NeoTreeFloatTitle",     { fg = C.keyword, bold = true })

  -- nvim-cmp.
  hl("CmpItemAbbr",          { fg = C.fg })
  hl("CmpItemAbbrDeprecated",{ fg = C.fg_dim, strikethrough = true })
  hl("CmpItemAbbrMatch",     { fg = C.func })
  hl("CmpItemAbbrMatchFuzzy",{ fg = C.func })
  hl("CmpItemKind",          { fg = C.type })
  hl("CmpItemKindText",      { fg = C.fg })
  hl("CmpItemKindMethod",    { fg = C.func })
  hl("CmpItemKindFunction",  { fg = C.func })
  hl("CmpItemKindConstructor", { fg = C.type })
  hl("CmpItemKindField",     { fg = C.variable })
  hl("CmpItemKindVariable",  { fg = C.variable })
  hl("CmpItemKindClass",     { fg = C.type })
  hl("CmpItemKindInterface", { fg = C.type })
  hl("CmpItemKindModule",    { fg = C.type })
  hl("CmpItemKindProperty",  { fg = C.variable })
  hl("CmpItemKindUnit",      { fg = C.number })
  hl("CmpItemKindValue",     { fg = C.fg })
  hl("CmpItemKindEnum",      { fg = C.type })
  hl("CmpItemKindKeyword",   { fg = C.keyword })
  hl("CmpItemKindSnippet",   { fg = C.fg_dim })
  hl("CmpItemKindColor",     { fg = C.number })
  hl("CmpItemKindFile",      { fg = C.fg })
  hl("CmpItemKindReference", { fg = C.keyword })
  hl("CmpItemKindFolder",    { fg = C.keyword })
  hl("CmpItemKindEnumMember",{ fg = C.constant })
  hl("CmpItemKindConstant",  { fg = C.constant })
  hl("CmpItemKindStruct",    { fg = C.type })
  hl("CmpItemKindEvent",     { fg = C.control })
  hl("CmpItemKindOperator",  { fg = C.operator })
  hl("CmpItemKindTypeParameter", { fg = C.variable })
  hl("CmpItemMenu",          { fg = C.fg_dim })

  -- vim-visual-multi (multicursor).
  hl("VM_Extend",          { bg = C.bg_sel })
  hl("VM_Cursor",          { bg = C.bg_sel, fg = C.fg_bright })
  hl("VM_Insert",          { bg = C.match })
  hl("VM_Mono",            { fg = C.bg, bg = C.func })
  hl("VM_Start",           { bg = "#2F4F2F" })
  hl("VM_End",             { bg = "#3B1F1F" })

  -- gitsigns.
  hl("GitSignsAddLn",     { fg = C.comment })
  hl("GitSignsChangeLn",  { fg = C.keyword })
  hl("GitSignsDeleteLn",  { fg = C.error })
  hl("GitSignsCurrentLineBlame", { fg = C.fg_dim })

  -- Indent blankline / indent guides if ever added.
  hl("IndentBlanklineChar",        { fg = C.border })
  hl("IndentBlanklineContextChar", { fg = C.keyword })
  hl("IblIndent",                  { fg = C.border })
  hl("IblWhitespace",              { fg = C.border })
  hl("IblScope",                   { fg = C.keyword })
end

M.load()
return M