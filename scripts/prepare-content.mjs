import fs from "node:fs/promises"
import path from "node:path"

const root = process.cwd()
const contentDir = path.join(root, "content")
const excluded = new Set([
  ".git",
  ".github",
  ".obsidian",
  ".quartz",
  ".quartz-cache",
  "content",
  "node_modules",
  "public",
  "quartz",
  "scripts",
])

async function exists(p) {
  try {
    await fs.access(p)
    return true
  } catch {
    return false
  }
}

async function rmChildren(dir) {
  await fs.mkdir(dir, { recursive: true })
  for (const entry of await fs.readdir(dir)) {
    await fs.rm(path.join(dir, entry), { recursive: true, force: true })
  }
}

function isMarkdownNote(name) {
  return name.toLowerCase().endsWith(".md") && name.toLowerCase() !== "readme.md"
}

async function main() {
  await rmChildren(contentDir)

  const entries = await fs.readdir(root, { withFileTypes: true })
  const notes = []

  for (const entry of entries) {
    if (excluded.has(entry.name)) continue
    const src = path.join(root, entry.name)
    const dest = path.join(contentDir, entry.name)

    if (entry.isFile() && isMarkdownNote(entry.name)) {
      await fs.copyFile(src, dest)
      notes.push(entry.name)
    } else if (entry.isDirectory() && entry.name === "assets") {
      await fs.cp(src, dest, { recursive: true })
    }
  }

  notes.sort((a, b) => a.localeCompare(b, "zh-CN"))
  const links = notes.map((name) => `- [[${name.replace(/\.md$/i, "")}]]`).join("\n")
  const index = `---\ntitle: Math in Computer Science\n---\n\n# Math in Computer Science\n\n这是从 Obsidian 笔记自动发布的课程笔记网站。\n\n## Notes\n\n${links}\n`
  await fs.writeFile(path.join(contentDir, "index.md"), index, "utf8")

  if (!(await exists(path.join(contentDir, "assets")))) {
    await fs.mkdir(path.join(contentDir, "assets"), { recursive: true })
  }
}

await main()
