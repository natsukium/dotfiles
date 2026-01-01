#!/usr/bin/env python3
import sys
from pathlib import Path


def remove_frontmatter(content: str) -> str:
    lines = content.split('\n')
    if lines and lines[0] == '---':
        for i, line in enumerate(lines[1:], 1):
            if line == '---':
                return '\n'.join(lines[i+1:])
    return content


def increase_header_depth(content: str) -> str:
    lines = content.split('\n')
    return '\n'.join(
        '#' + line if line.startswith('#') else line
        for line in lines
    )


def main():
    agents_md = Path(sys.argv[1]).read_text()
    skills_dir = Path(sys.argv[2])

    output = agents_md + '\n# Tool Usage Instructions'

    # Append each skill
    for skill_md in sorted(skills_dir.glob('*/SKILL.md')):
        content = increase_header_depth(remove_frontmatter(skill_md.read_text()))
        output += f'\n{content}'

    print(output)


if __name__ == '__main__':
    main()
