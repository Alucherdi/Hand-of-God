# Hand of God

Yet another jumper, file manager, and greper with utilities to streamline editing workflows.

⚠️ Early Access – Features may change significantly!

## 🚀 Main Features

* **Fast navigation** through files and buffers.
* **File jumping with automatic management for ghost files,** so you don't jump into already deleted files.
* Text / File searching.
* Simple and efficient **file explorer** with an integrated **buffer editor** for managing opened files like a normal nvim buffer.

## ⚙️ Requirements

* **Neovim 0.11+** (latest stable version recommended).
* [https://github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)
* [https://github.com/sharkdp/fd](https://github.com/sharkdp/fd)

## 📥 Installation

Using `lazy.nvim`:

```lua
{
    "alucherdi/hand-of-god"
}
```

## 🔧 Configuration

```lua
local jumper = require('handofgod.jumper')
jumper.setup()

-- add file to jumper list
vim.keymap.set("n", "<leader>a", function() jumper.add() end)
-- explore jumper list as buffer
vim.keymap.set("n", "<leader>e", function() jumper:explore() end)

-- jump bindings
vim.keymap.set("n", "<C-h>", function() jumper.jump_to(1) end)
vim.keymap.set("n", "<C-j>", function() jumper.jump_to(2) end)
vim.keymap.set("n", "<C-k>", function() jumper.jump_to(3) end)
vim.keymap.set("n", "<C-l>", function() jumper.jump_to(4) end)

local manager = require('handofgod.manager')
manager:setup {
    -- ignore paths or folders
    ignore = {},
    -- write automatically when closing the manager
    write_on_exit = true,
    -- ask for confirmation when you attempt to save
    ask_confirmation = true,

    --keybinds for each action
    keybinds = {
        rename_file = '<leader>rn',
        write_prompt = '<leader>w',
        push_back = '<BS>',
        close = {'<Esc>', 'q'},
        go_to = '<CR>',
        add_to_jump_list = '<leader>a'
    },

    -- rename window config
    rename = {
        keybinds = {
            save_and_exit = 'q',
            exit = '<Esc>'
        }
    },

    -- save confirmation window config
    save_confirmation = {
        keybinds = {
            confirm = 'y',
            cancel  = 'n',
        }
    }
}
-- file explorer/manager
vim.keymap.set("n", "<C-e>", function() manager:open() end)

local searcher = require('handofgod.searcher')
searcher:setup {
    ignore = {
        'node_modules', 'lib', 'libs', 'bin', 'build'
    },
    -- instead of: a/veeeeery/laaaaaaarge/paaaaaath/tooooooo/file.lua 
    -- you have:   a/v/l/p/t/file.lua
    -- 64 char length to contract
    contract_on_large_paths = true,
    case_sensitive = false,
}

vim.keymap.set("n", "<C-p>", function() searcher:open() end)

local finder = require('handofgod.finder')
finder:setup {}
vim.keymap.set('n', '<C-f>', function() finder:open() end)

```

### 🔑 Hardcoded Keybinds (To be made configurable)

These keybindings are currently hardcoded but will be made configurable through the respective module setups in future updates.

#### 🔍 Finder

```text
<C-f>       - Reopen the prompt inside the finder buffer
```

#### ✏️ Rename Window

```text
q           - Save and quit inside the rename window
```

## 📚 Documentation

Access the complete documentation directly from Neovim:

```
:help handofgod
```

## 🐞 Issues and Suggestions

Report any issues or suggestions on the [GitHub repository](https://github.com/Alucherdi/handofgod.nvim/issues).

## 📜 License

Hand of God is available under the MIT license.


