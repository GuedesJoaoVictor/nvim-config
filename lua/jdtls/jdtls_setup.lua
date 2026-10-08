local M = {}

local jdk21 = vim.fn.expand("~/Library/Java/JavaVirtualMachines/temurin-21.0.8/Contents/Home")

function M:setup()
  local jdtls_dir = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
  local launcher = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)[1]
  if not launcher then
    vim.notify("jdtls não instalado. Rode :MasonInstall jdtls", vim.log.levels.ERROR)
    return
  end

  local root = require("jdtls.setup").find_root({ "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
  local workspace = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. vim.fn.fnamemodify(root or vim.fn.getcwd(), ":t")
  local os_name = (vim.uv or vim.loop).os_uname().sysname
  local cfg = os_name == "Darwin" and (jit.arch == "arm64" and "config_mac_arm" or "config_mac") or os_name == "Linux" and "config_linux" or "config_win"

  require("jdtls").start_or_attach({
    cmd = {
      jdk21 .. "/bin/java", -- jdtls precisa de Java 21+ (o projeto compila com o JDK abaixo)
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Xmx1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens", "java.base/java.util=ALL-UNNAMED",
      "--add-opens", "java.base/java.lang=ALL-UNNAMED",
      "-javaagent:" .. jdtls_dir .. "/lombok.jar", -- precisa ser um único argumento "-javaagent:<path>"
      "-jar", launcher,
      "-configuration", jdtls_dir .. "/" .. cfg,
      "-data", workspace,
    },
    root_dir = root,
    settings = {
      java = {
        configuration = {
          runtimes = {
            -- ponytail: ajuste o JDK do projeto PNIP aqui se não for 17
            { name = "JavaSE-17", path = "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home", default = true },
            { name = "JavaSE-21", path = jdk21 },
          },
        },
        import = { maven = { enabled = true }, gradle = { enabled = true } },
      },
    },
  })
end

return M
