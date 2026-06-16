from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple


@dataclass(frozen=True)
class UatSection:
    title: str
    headers: List[str]
    rows: List[List[str]]


def _clean_cell(s: str) -> str:
    s = s.strip()
    s = s.replace("<br>", "\n")
    s = re.sub(r"\*\*(.*?)\*\*", r"\1", s)  # remove bold markers
    s = re.sub(r"\s+\n", "\n", s)
    return s


def _split_md_table_row(line: str) -> List[str]:
    # Remove leading/trailing pipe and split
    raw = [c.strip() for c in line.strip().strip("|").split("|")]
    return [_clean_cell(c) for c in raw]


def parse_sections_from_md(md: str) -> List[UatSection]:
    lines = md.splitlines()
    sections: List[UatSection] = []

    i = 0
    current_title = None
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("## "):
            current_title = line[3:].strip()
            i += 1
            # seek a markdown table after the heading
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            if i >= len(lines) or "|" not in lines[i]:
                continue

            header_line = lines[i].rstrip()
            if not header_line.strip().startswith("|"):
                continue
            headers = _split_md_table_row(header_line)

            i += 1
            # separator line like |---|---|
            if i < len(lines) and re.match(r"^\s*\|\s*-", lines[i]):
                i += 1

            rows: List[List[str]] = []
            while i < len(lines):
                l = lines[i].rstrip()
                if l.strip() == "" or l.lstrip().startswith("## "):
                    break
                if l.strip().startswith("|"):
                    row = _split_md_table_row(l)
                    # normalize row length
                    if len(row) < len(headers):
                        row += [""] * (len(headers) - len(row))
                    elif len(row) > len(headers):
                        row = row[: len(headers)]
                    rows.append(row)
                i += 1

            if current_title and headers and rows:
                sections.append(UatSection(title=current_title, headers=headers, rows=rows))
            continue

        i += 1

    return sections


def build_pdf(input_md_path: Path, output_pdf_path: Path) -> None:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    md = input_md_path.read_text(encoding="utf-8")
    sections = parse_sections_from_md(md)
    if not sections:
        raise SystemExit("No sections/tables found in markdown.")

    output_pdf_path.parent.mkdir(parents=True, exist_ok=True)

    doc = SimpleDocTemplate(
        str(output_pdf_path),
        pagesize=landscape(A4),
        leftMargin=18,
        rightMargin=18,
        topMargin=18,
        bottomMargin=18,
        title="UAT Test Cases — Home Workers",
    )

    styles = getSampleStyleSheet()
    title_style = styles["Title"]
    h2_style = ParagraphStyle(
        "H2",
        parent=styles["Heading2"],
        spaceBefore=10,
        spaceAfter=6,
    )
    cell_style = ParagraphStyle(
        "Cell",
        parent=styles["BodyText"],
        fontSize=8,
        leading=10,
    )
    header_style = ParagraphStyle(
        "HeaderCell",
        parent=cell_style,
        fontSize=8,
        leading=10,
        textColor=colors.white,
    )

    story = []
    story.append(Paragraph("UAT Test Cases — Home Workers", title_style))
    story.append(Spacer(1, 10))

    for sec in sections:
        story.append(Paragraph(sec.title, h2_style))

        data: List[List[Paragraph]] = []
        data.append([Paragraph(h, header_style) for h in sec.headers])

        for r in sec.rows:
            data.append([Paragraph(c.replace("\n", "<br/>"), cell_style) for c in r])

        table = Table(data, repeatRows=1)
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f2937")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 8),
                    ("ALIGN", (0, 0), (-1, 0), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#9ca3af")),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f9fafb")]),
                    ("LEFTPADDING", (0, 0), (-1, -1), 4),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 3),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ]
            )
        )

        story.append(table)
        story.append(Spacer(1, 12))

    doc.build(story)


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    input_md = repo_root / "docs" / "uat-test-cases-home-workers.md"
    output_pdf = repo_root / "docs" / "uat-test-cases-home-workers.pdf"
    build_pdf(input_md, output_pdf)
    print(f"Generated: {output_pdf}")


if __name__ == "__main__":
    main()

