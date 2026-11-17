# ruff: noqa: T201, C901, PLR0912, PLR0915, PLR0911, FBT001, PLR2004
"""
Analyzes presentation markdown for potential overflow issues.
Reports lines and slide numbers that may cause content overflow.
"""

import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class OverflowIssue:
    slide_number: int
    line_number: int
    issue_type: str
    details: str
    line_content: str = ""


def calculate_line_height(line: str, prev_line_was_heading: bool) -> float:
    """Calculate effective height of a line in presentation units."""
    line = line.strip()

    # Empty line spacing
    if not line:
        return 0.5 if prev_line_was_heading else 0.3

    # Headings take more space
    if line.startswith("## "):
        return 2.5  # Main heading
    if line.startswith("### "):
        return 2.0  # Subheading

    # Bold section headers
    if line.startswith("**") and line.endswith(":**"):
        return 1.8

    # Bullet points (including nested)
    if line.startswith(("- ", "* ")):
        # Check for long bullets (wrapped lines take more space)
        if len(line) > 80:
            return 1.5
        return 1.2

    # Regular text
    # Long lines wrap and take more vertical space
    if len(line) > 80:
        return 1.5

    return 1.0


def analyze_presentation_overflow(
    md_file: Path,
) -> tuple[list[OverflowIssue], Path]:
    """Analyze markdown file for potential overflow issues."""
    with md_file.open(encoding="utf-8") as f:
        lines = f.readlines()

    issues: list[OverflowIssue] = []
    slide_number = 1
    slide_start_line = 1
    slide_lines_count = 0
    slide_effective_height = 0.0
    in_mermaid_block = False
    in_code_block = False
    mermaid_block_start_line = 0
    mermaid_block_lines = 0
    prev_line_was_heading = False

    # Thresholds
    max_line_length = 120
    max_slide_effective_height = 16.0  # Effective height units
    max_mermaid_lines = 30
    large_code_block_lines = 15
    yaml_frontmatter_max_line = 10

    for i, line in enumerate(lines, start=1):
        line_stripped = line.rstrip()

        # Track slide boundaries
        if i > 1 and line_stripped == "---":
            # Check slide effective height before moving to next slide
            if slide_effective_height > max_slide_effective_height:
                details = (
                    f"Slide height: {slide_effective_height:.1f} units "
                    f"(max: {max_slide_effective_height})"
                )
                issues.append(
                    OverflowIssue(
                        slide_number=slide_number,
                        line_number=slide_start_line,
                        issue_type="SLIDE_OVERFLOW",
                        details=details,
                    )
                )

            slide_number += 1
            slide_start_line = i + 1
            slide_lines_count = 0
            slide_effective_height = 0.0
            prev_line_was_heading = False
            continue

        # Skip YAML frontmatter
        if i <= yaml_frontmatter_max_line and (
            line_stripped.startswith("---") or line_stripped.endswith(":")
        ):
            continue

        # Track mermaid blocks
        if "```mermaid" in line_stripped:
            in_mermaid_block = True
            mermaid_block_start_line = i
            mermaid_block_lines = 0
            slide_effective_height += 0.5  # Opening marker
            continue
        if in_mermaid_block and "```" in line_stripped:
            in_mermaid_block = False
            slide_effective_height += 0.5  # Closing marker
            # Mermaid diagrams have their own height calculation
            diagram_height = min(mermaid_block_lines * 0.4, 12.0)
            slide_effective_height += diagram_height
            if mermaid_block_lines > max_mermaid_lines:
                details = (
                    f"Mermaid diagram has {mermaid_block_lines} lines (max: {max_mermaid_lines})"
                )
                issues.append(
                    OverflowIssue(
                        slide_number=slide_number,
                        line_number=mermaid_block_start_line,
                        issue_type="MERMAID_TOO_LARGE",
                        details=details,
                    )
                )
            continue

        if in_mermaid_block:
            mermaid_block_lines += 1
            continue

        # Track code blocks
        if line_stripped.startswith("```") and not in_code_block:
            in_code_block = True
            code_block_start_line = i
            code_block_lines = 0
            slide_effective_height += 0.5
            continue
        if in_code_block and line_stripped.startswith("```"):
            in_code_block = False
            slide_effective_height += 0.5
            # Code blocks take significant vertical space
            slide_effective_height += code_block_lines * 0.8
            if code_block_lines > large_code_block_lines:
                details = f"Code block has {code_block_lines} lines (max: {large_code_block_lines})"
                issues.append(
                    OverflowIssue(
                        slide_number=slide_number,
                        line_number=code_block_start_line,
                        issue_type="CODE_BLOCK_TOO_LARGE",
                        details=details,
                    )
                )
            continue

        if in_code_block:
            code_block_lines += 1
            continue

        # Skip HTML comments
        if line_stripped.startswith("<!--"):
            continue

        # Check line length
        if line_stripped and len(line_stripped) > max_line_length:
            details = f"Line length: {len(line_stripped)} chars (max: {max_line_length})"
            issues.append(
                OverflowIssue(
                    slide_number=slide_number,
                    line_number=i,
                    issue_type="LINE_TOO_LONG",
                    details=details,
                    line_content=line_stripped,
                )
            )

        # Calculate effective height for this line
        line_height = calculate_line_height(line_stripped, prev_line_was_heading)
        slide_effective_height += line_height

        # Track if current line is a heading for next iteration
        prev_line_was_heading = line_stripped.startswith("##")

        # Count content lines
        if line_stripped:
            slide_lines_count += 1

    # Check last slide
    if slide_effective_height > max_slide_effective_height:
        details = (
            f"Slide height: {slide_effective_height:.1f} units (max: {max_slide_effective_height})"
        )
        issues.append(
            OverflowIssue(
                slide_number=slide_number,
                line_number=slide_start_line,
                issue_type="SLIDE_OVERFLOW",
                details=details,
            )
        )

    return issues, md_file


def print_overflow_report(issues: list[OverflowIssue], md_file: Path) -> None:
    """Print a formatted overflow report."""
    if not issues:
        print("✓ No overflow issues detected!")
        return

    print(f"Found {len(issues)} potential overflow issue(s):\n")

    # Group by slide
    issues_by_slide: dict[int, list[OverflowIssue]] = {}
    for issue in issues:
        if issue.slide_number not in issues_by_slide:
            issues_by_slide[issue.slide_number] = []
        issues_by_slide[issue.slide_number].append(issue)

    for slide_num in sorted(issues_by_slide.keys()):
        for issue in issues_by_slide[slide_num]:
            clickable_link = f"{md_file}:{issue.line_number}"
            print(f"{clickable_link} - {issue.issue_type} - {issue.details}")
        print()

    separator = "=" * 40
    print(separator)
    print("RECOMMENDATIONS:")
    print(separator)
    print("- LINE_TOO_LONG: Break into multiple lines or use abbreviations")
    print("- SLIDE_OVERFLOW: Split content into multiple slides")
    print("- MERMAID_TOO_LARGE: Simplify diagram or split across slides")
    print("- CODE_BLOCK_TOO_LARGE: Show only relevant excerpts")
    print(separator)


def main() -> int:
    """Main entry point."""
    expected_arg_count = 2
    if len(sys.argv) != expected_arg_count:
        print("Usage: check_presentation_overflow.py <markdown_file>", file=sys.stderr)
        return 2

    md_file = Path(sys.argv[1])
    if not md_file.exists():
        print(f"ERROR: File not found: {md_file}", file=sys.stderr)
        return 1

    issues, file_path = analyze_presentation_overflow(md_file)
    print_overflow_report(issues, file_path)

    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
