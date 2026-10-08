return {
  { "neovim/nvim-lspconfig" },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "jdtls" } },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_enable = {
        exclude = {
          "jdtls",
        },
      },
    },
  },
  { "mfussenegger/nvim-jdtls" },
  { "Decodetalkers/csharpls-extended-lsp.nvim" },
}
