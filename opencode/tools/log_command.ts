import { tool } from "@opencode-ai/plugin"
import fs from "fs"
import os from "os"
import path from "path"

const LOG_FILE = path.join(os.homedir(), ".ai-commands.log")

function flatten(command: string): string {
  return command
    .replace(/\\\n\s*/g, " ")  // join continuation lines
    .replace(/\n+/g, " ")      // flatten any remaining newlines
    .trim()
}

export default tool({
  description: "Log a shell command suggested to the user. Call this only when the user explicitly asks for a command to run themselves.",
  args: {
    command: tool.schema.string().describe("The shell command exactly as shown to the user"),
    description: tool.schema.string().describe("Short phrase describing what the command does (e.g. 'list PRs assigned to user')"),
    tool: tool.schema.string().describe("The main CLI tool used (e.g. gh, git, npm, docker)"),
  },
  async execute(args) {
    const command = flatten(args.command)
    const date = new Date().toISOString().slice(0, 10)
    const entry = `${date} | ${args.description} | ${args.tool} | ${command}`

    let lines: string[] = []
    if (fs.existsSync(LOG_FILE)) {
      lines = fs.readFileSync(LOG_FILE, "utf-8").split("\n").filter(Boolean)
    }

    // Deduplicate — remove existing entry with same command (regardless of date)
    lines = lines.filter((line) => {
      const parts = line.split(" | ")
      const cmd = parts[parts.length - 1]
      return cmd !== command
    })

    // Append new entry at the end
    lines.push(entry)

    fs.writeFileSync(LOG_FILE, lines.join("\n") + "\n")

    return `Logged: ${command}`
  },
})
