---
name: nvim-config
description: Use when discussing or editing the Neovim setup under config/nvim/.config/nvim, including plugins, keymaps, layout, startup flow, and UX choices.
---

# Nvim Config

## Purpose
- Keep Neovim changes intentional, explain the setup first, and keep docs current.

## Use When
- The task is about `config/nvim/.config/nvim/**`
- The user asks how the Neovim setup works
- The task changes plugins, keymaps, layout, startup flow, or editor UX

## Do Not Use When
- The task is about non-Neovim config
- The task only mentions Vim generically without touching this setup

## Rules
- Before editing, explain the intended Neovim setup for the change in 2-6 lines.
- Say what role the change plays: plugin, keymap, layout, startup, LSP, formatting, search, or UI.
- Prefer minimal changes that fit the existing setup.
- Keep plugin configuration in `lua/plugins/` and repo behavior in `lua/features/` or `lua/config/`.
- Maintain `config/nvim/.config/nvim/README.md` when structure, plugins, keymaps, or user-facing behavior meaningfully change.
- The README must describe the layout, configuration model, key shortcuts, and active plugins with a short purpose for each.

## README Requirements
- Include: overview, layout, configuration model, startup flow, key shortcuts, plugin list.
- Document plugins from `lua/plugins/*.lua`.
- For grouped plugins like `mini.nvim`, list enabled modules that are configured here.
- Document both custom mappings and important plugin mappings relied on by this setup.
- Explain where behavior belongs: `lua/config/`, `lua/features/`, and `lua/plugins/`.
- Keep each plugin description short and practical.

## Verification
- Check whether the change affects docs; update the README if yes.
- Confirm the explanation-first note was given before substantial edits.
- Confirm any added plugin is documented.

## Maintenance
- Last reviewed: 2026-06-18
- Status: active
- Sources of truth: `config/nvim/.config/nvim/`, `config/nvim/.config/nvim/lua/plugins/`, `config/nvim/.config/nvim/README.md`
