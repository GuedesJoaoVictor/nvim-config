return {
  { "neovim/nvim-lspconfig" },
  {
    "mason-org/mason.nvim",
  },
  {
    "mason-lsp/mason-lspconfig.nvim",
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
