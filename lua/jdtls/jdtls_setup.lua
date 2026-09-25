local M = {}

function M:setup()
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local workspace_dir = vim.fn.stdpath("data")
    .. package.config:sub(1, 1)
    .. "jdtls-workspace"
    .. package.config:sub(1, 1)
    .. project_name
  local os_name = (vim.uv or vim.loop).os_uname().sysname
  local java_bin = vim.fn.exepath("java") ~= "" and vim.fn.exepath("java") or "java"
  -- jdtls >= 1.60 requires Java 21+ to run.
  local function java_major(ver)
    local major = ver:match("version[^\n]*\"(%d+)")
    return tonumber(major) or 0
  end
  local function major_of(bin)
    if not bin or bin == "" then
      return 0
    end
    local out = vim.fn.system({ bin, "-version" })
    if vim.v.shell_error ~= 0 then
      return 0
    end
    return java_major(out)
  end
  if major_of(java_bin) < 21 then
    local sep = package.config:sub(1, 1)
    local sdkman_candidates = vim.env.SDKMAN_CANDIDATES_DIR
      or (vim.env.HOME and vim.env.HOME .. "/.sdkman/candidates")
    local sdkman_dir = sdkman_candidates
      and vim.fn.isdirectory(sdkman_candidates) == 1
          and sdkman_candidates .. sep .. "java"
      or nil
    if sdkman_dir and vim.fn.isdirectory(sdkman_dir) ~= 1 then
      sdkman_dir = nil
    end
    local found_21 = nil
    if sdkman_dir and vim.fn.isdirectory(sdkman_dir) == 1 then
      for _, v in ipairs(vim.fn.glob(sdkman_dir .. "/*", false, true)) do
        local name = vim.fn.fnamemodify(v, ":t")
        local major = name:match("^(%d+).")
        if major and tonumber(major) >= 21 then
          local bin = v .. "/bin/java"
          if vim.fn.executable(bin) == 1 and (not found_21 or name > found_21) then
            found_21 = bin
          end
        end
      end
    end
    if not found_21 then
      local home_bin = vim.env.JAVA_HOME and vim.env.JAVA_HOME .. "/bin/java" or nil
      if home_bin and major_of(home_bin) >= 21 then
        found_21 = home_bin
      end
    end
    if found_21 then
      java_bin = found_21
    else
      vim.notify(
        "jdtls precisa de Java 21+ para rodar, mas só encontrou Java "
          .. major_of(vim.fn.exepath("java"))
          .. ". Instale um JDK 21+ e configure JAVA_HOME.",
        vim.log.levels.ERROR
      )
    end
  end
  local jdtls_dir = vim.fn.stdpath("data")
    .. package.config:sub(1, 1)
    .. "mason"
    .. package.config:sub(1, 1)
    .. "packages"
    .. package.config:sub(1, 1)
    .. "jdtls"

  local launcher = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)[1]
  if not launcher or launcher == "" then
    vim.notify("Launcher do jdtls não encontrado. Reinstale via :MasonInstall jdtls", vim.log.levels.ERROR)
    return
  end

  local config = {
    -- The command that starts the language server
    -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {

      -- 💀
      java_bin, -- or '/path/to/java21_or_newer/bin/java'
      -- depends on if `java` is in your $PATH env variable and if it points to the right version.

      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xmx1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",

      "--add-opens",
      "java.base/java.net=ALL-UNNAMED",

      -- 💀
      "-jar",
      launcher,
      -- Must point to the                                                     Change this to
      -- eclipse.jdt.ls installation                                           the actual version

      -- 💀
      "-configuration",
      jdtls_dir
        .. package.config:sub(1, 1)
        .. "config_"
        .. (os_name == "Windows_NT" and "win" or os_name == "Linux" and "linux" or "mac"),
      -- eclipse.jdt.ls installation            Depending on your system.

      -- 💀
      -- See `data directory configuration` section in the README
      "-data",
      workspace_dir,

      "-javaagent",
      jdtls_dir .. package.config:sub(1, 1) .. "lombok.jar",
    },

    -- 💀
    -- This is the default if not provided, you can remove it. Or adjust as needed.
    -- One dedicated LSP server & client will be started per unique root_dir
    root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

    -- Here you can configure eclipse.jdt.ls specific settings
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    -- for a list of options
    settings = {
      java = {},
    },

    -- Language server `initializationOptions`
    -- You need to extend the `bundles` with paths to jar files
    -- if you want to use additional eclipse.jdt.ls plugins.
    --
    -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
    --
    -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
    init_options = {
      bundles = {},
    },
  }
  -- This starts a new client & server,
  -- or attaches to an existing client & server depending on the `root_dir`.
  require("jdtls").start_or_attach(config)
end

return M
