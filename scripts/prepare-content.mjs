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

async function rmChildren(dir) {
  await fs.mkdir(dir, { recursive: true })
  for (const entry of await fs.readdir(dir)) {
    await fs.rm(path.join(dir, entry), { recursive: true, force: true })
  }
}

function isMarkdownNote(name) {
  return name.toLowerCase().endsWith(".md") && name.toLowerCase() !== "readme.md"
}

function hideImagesForPublicSite(markdown) {
  let hidden = false
  const marker = "**[图片已在公网隐藏：本机 Obsidian 仍可查看原图]**"

  // Hide Obsidian image embeds: ![[...]]
  markdown = markdown.replace(/!\[\[[^\]]+\]\]/g, () => {
    hidden = true
    return marker
  })

  // Hide standard Markdown image embeds: ![alt](path)
  markdown = markdown.replace(/!\[[^\]]*\]\([^\)]+\)/g, () => {
    hidden = true
    return marker
  })

  if (hidden && !markdown.includes("public-images-hidden: true")) {
    return `<!-- public-images-hidden: true -->\n\n${markdown}`
  }
  return markdown
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
      const raw = await fs.readFile(src, "utf8")
      await fs.writeFile(dest, hideImagesForPublicSite(raw), "utf8")
      notes.push(entry.name)
    }
  }

  notes.sort((a, b) => a.localeCompare(b, "zh-CN"))
  const links = notes.map((name) => `- [[${name.replace(/\.md$/i, "")}]]`).join("\n")
  const index = `---\ntitle: Math in Computer Science\n---\n\n# Math in Computer Science\n\n这是从 Obsidian 笔记自动发布的课程笔记网站。\n\n> 图片已在公网隐藏；本机 Obsidian 仍可查看原图。\n\n## Notes\n\n${links}\n`
  await fs.writeFile(path.join(contentDir, "index.md"), index, "utf8")
}

await main()
