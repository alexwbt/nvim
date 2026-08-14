return {
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'jvgrootveld/telescope-zoxide',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  }
}
