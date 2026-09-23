return {
  "Jezda1337/nvim-html-css",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    enable_on = { "html" },
    style_sheets = {
      "./node_modules/@govbr-ds/core/dist/core.css",
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
    },
  },
}
