local M = {}

local function find_jdk_home(java_major)
  local os_name = (vim.uv or vim.loop).os_uname().sysname
  local candidates = {}

  if os_name == "Linux" then
    table.insert(candidates, vim.fn.expand("~/.sdkman/candidates/java/" .. java_major .. ".*")) -- SDKMAN
    if java_major == 17 then
      table.insert(candidates, "/usr/lib/jvm/java-17-openjdk")
      table.insert(candidates, "/usr/lib/jvm/java-17-openjdk-amd64")
      table.insert(candidates, "/usr/lib/jvm/java-17")
    elseif java_major == 21 then
      table.insert(candidates, "/usr/lib/jvm/java-21-openjdk")
      table.insert(candidates, "/usr/lib/jvm/java-21-openjdk-amd64")
      table.insert(candidates, "/usr/lib/jvm/java-21")
    end
  elseif os_name == "Darwin" then
    if java_major == 17 then
      table.insert(candidates, "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home") -- arm64
      table.insert(candidates, "/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home")  -- intel
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/temurin-17*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/openjdk-17*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/zulu-17*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/corretto-17*/Contents/Home")
    elseif java_major == 21 then
      table.insert(candidates, "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
      table.insert(candidates, "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home")
      table.insert(candidates, "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home")
      table.insert(candidates, "/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/temurin-21*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/openjdk-21*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/zulu-21*/Contents/Home")
      table.insert(candidates, "/Library/Java/JavaVirtualMachines/corretto-21*/Contents/Home")
    end
  end

  for _, c in ipairs(candidates) do
    if c:match("%*") then
      local matches = vim.fn.glob(c, false, true)
      if #matches > 0 then
        return matches[1]
      end
    else
      if vim.fn.isdirectory(c) == 1 then
        return c
      end
    end
  end

  return nil
end

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

  local jdk21 = find_jdk_home(21)
  local jdk17 = find_jdk_home(17)

  if not jdk21 then
    vim.notify("Não encontrei JDK 21 para rodar o jdtls. Ajuste find_jdk_home no jdtls_setup.lua", vim.log.levels.ERROR)
    return
  end

  local runtimes = { { name = "JavaSE-21", path = jdk21 } }
  if jdk17 then
    table.insert(runtimes, 1, { name = "JavaSE-17", path = jdk17, default = true })
  else
    runtimes[1].default = true
  end

  require("jdtls").start_or_attach({
    cmd = {
      jdk21 .. "/bin/java",
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Xmx1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens", "java.base/java.util=ALL-UNNAMED",
      "--add-opens", "java.base/java.lang=ALL-UNNAMED",
      "-javaagent:" .. jdtls_dir .. "/lombok.jar",
      "-jar", launcher,
      "-configuration", jdtls_dir .. "/" .. cfg,
      "-data", workspace,
    },
    root_dir = root,
    settings = {
      java = {
        configuration = {
          runtimes = runtimes,
        },
        import = { maven = { enabled = true }, gradle = { enabled = true } },
      },
    },
  })

end

return M
