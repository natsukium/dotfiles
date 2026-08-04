// Reuse project-local Claude skills without maintaining parallel
// `.agents/skills` copies. Global Claude skills stay excluded because Home
// Manager already installs the shared set into pi, where duplicates collide.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

function findGitRepoRoot(startDir: string): string | null {
  let dir = resolve(startDir);
  while (true) {
    if (existsSync(join(dir, ".git"))) {
      return dir;
    }
    const parent = dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

function collectProjectClaudeSkillDirs(startDir: string): string[] {
  const resolvedStart = resolve(startDir);
  const homeClaudeSkills = resolve(homedir(), ".claude", "skills");
  const gitRepoRoot = findGitRepoRoot(resolvedStart);

  const dirs: string[] = [];
  let dir = resolvedStart;
  while (true) {
    const candidate = join(dir, ".claude", "skills");
    if (candidate !== homeClaudeSkills && existsSync(candidate)) {
      dirs.push(candidate);
    }
    if (gitRepoRoot && dir === gitRepoRoot) {
      break;
    }
    const parent = dirname(dir);
    if (parent === dir) {
      break;
    }
    dir = parent;
  }
  return dirs;
}

export default function (pi: ExtensionAPI) {
  pi.on("resources_discover", (event, ctx) => {
    if (!ctx.isProjectTrusted()) {
      return;
    }
    return { skillPaths: collectProjectClaudeSkillDirs(event.cwd) };
  });
}
