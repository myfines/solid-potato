---
name: tia-v20-agent
description: Operate TIA Portal V20 projects through Openness and MCP using an autonomous plan-observe-act loop, including project files, PLC devices, blocks, tags, SCL, compilation, backup, and optional PLCSIM download.
---

# TIA V20 Agent

Use this skill when the task involves operating a TIA Portal V20 project, generating PLC logic, importing SCL, compiling, backing up, or connecting to PLCSIM.

## Operating policy

- Act as the primary agent: inspect the project, choose the next tool from the observed result, verify the result, and decide whether the goal is complete.
- Do not narrate private chain-of-thought or repeated deliberation. User-facing output should contain concise progress, tool results, file paths, token usage, and the final report. Keep detailed diagnostics in debug logs.
- Do not impose an arbitrary step or round limit. Continue while progress is being made and stop when the task is complete, the user stops it, a tool is unavailable, or the next action requires missing information.
- Detect identical action/observation loops and stop that loop with a useful explanation instead of retrying indefinitely.
- Before every mutation, identify the exact project path and target object. Prefer a backup before destructive or broad changes.
- Before deleting an existing block, tag table, device, or source, call `tia_backup_project` with the complete `.ap20` path and a new backup directory. Never substitute the SCL apply tool for a backup-only operation.
- When the user enables unrestricted mode, do not ask for repeated in-app confirmations; still report exactly what changed and never claim a download or online connection without a returned success result.

## Tool selection

- Read the current session/project/device structure before changing it, unless the user gave a precise existing target and the required context is already known.
- If a requested source file does not exist, use the local file-writing capability to create it. Do not repeatedly try source-generation tools that only export existing blocks.
- After creating or importing an object, re-read it with the corresponding list/get tool and report the absolute project or file path.
- For SCL: create the source file, add it as an external source, generate blocks, compile, save, and verify the block/source result.
- In SCL blocks, declare VAR_INPUT/VAR_OUTPUT/VAR variables without a prefix, and reference those declared variables in executable statements with the `#` prefix (for example `#Start_Button`, `#Run_Latch`). Quoted names such as `"Start_Button"` refer to global symbols and must not be used for block interface variables.
- Prefer the composite `tia_apply_scl` tool for write/add/generate/compile/save. If it returns a compile error, report the returned diagnostics and revise the source once with evidence; do not guess or cycle through unrelated source tools.
- For PLCSIM: automatically discover a PLCSIM/virtual/softbus interface; never substitute a physical Wi-Fi/Ethernet adapter. If standard PLCSIM does not expose a usable target, explain the one-time manual setup required.

## Output

- Stream the final answer text to the chat pane.
- Keep the progress pane for concise phases such as `planning`, `running tool`, `success`, `error`, `stopped`, and `usage`; do not put token-by-token model text there.
- Show cumulative prompt/completion/total token usage when the provider supplies it, otherwise label the estimate.
- Always include: operation status, exact project path, changed objects, generated file paths, compile diagnostics, backup path, and any uncompleted step.
