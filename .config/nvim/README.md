# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Databases

Database configuration lives in `lua/plugins/dbee.lua`. Open nvim-dbee with
`:Dbee` or `<leader>D`. In its editor, `BB` executes the file (or the visual
selection); `<CR>` executes the query under the cursor.

The 11 local PostgreSQL and two Redis connections are provided by a memory
source. Additional connections can use `DBEE_CONNECTIONS` or Dbee's persistent
connection editor. Scratch queries remain in `~/Documents/sql/scratch`;
existing SQL files are unchanged. SQL treesitter, sqlfluff formatting and
linting remain enabled. SQL completion uses `cmp-dbee` through `blink.compat`,
alongside Blink's existing sources. Open Dbee and select an active connection
before completing. Metadata may take a second to load. Schema/table suggestions
come from that connection; use a table alias followed by `.` for column
suggestions. The source supports `sql` buffers, not Redis commands.

Go is required to build the matching backend: upstream prebuilt binaries lag
Redis URL/TLS support. Redis uses TLS with hostname/SNI and certificate
verification; the current local Redis certificates are rejected as
non-standards-compliant. Repair those certificates before using Redis here.
