import os
import html
import re
from io import BytesIO
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
    KeepTogether,
    HRFlowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY

from schemas.exam_schema import Class9TestSchema


def escape_for_paragraph(text: str) -> str:
    """Safely escapes raw text for ReportLab Paragraphs while allowing safe styling tags."""
    if not text:
        return ""
    s = str(text)
    # Temporarily preserve intentional styling tags
    s = s.replace("<b>", "__B_OPEN__").replace("</b>", "__B_CLOSE__")
    s = s.replace("<i>", "__I_OPEN__").replace("</i>", "__I_CLOSE__")
    s = s.replace("<sub>", "__SUB_OPEN__").replace("</sub>", "__SUB_CLOSE__")
    s = s.replace("<sup>", "__SUP_OPEN__").replace("</sup>", "__SUP_CLOSE__")
    
    # Escape XML entities
    s = html.escape(s)
    
    # Restore safe styling tags
    s = s.replace("__B_OPEN__", "<b>").replace("__B_CLOSE__", "</b>")
    s = s.replace("__I_OPEN__", "<i>").replace("__I_CLOSE__", "</i>")
    s = s.replace("__SUB_OPEN__", "<sub>").replace("__SUB_CLOSE__", "</sub>")
    s = s.replace("__SUP_OPEN__", "<sup>").replace("__SUP_CLOSE__", "</sup>")
    return s


def create_exam_styles():
    """Generates custom typography styles for school exam papers."""
    styles = getSampleStyleSheet()

    # Document Header Style
    styles.add(
        ParagraphStyle(
            "ExamHeader",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=16,
            leading=20,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#1A365D"),
        )
    )

    # Section Headers
    styles.add(
        ParagraphStyle(
            "SectionHeader",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=16,
            alignment=TA_LEFT,
            textColor=colors.HexColor("#2B6CB0"),
            spaceBefore=10,
            spaceAfter=6,
        )
    )

    # Standard Question Body
    styles.add(
        ParagraphStyle(
            "QuestionBody",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            alignment=TA_JUSTIFY,
            spaceBefore=3,
            spaceAfter=3,
        )
    )

    # MCQ Option Style
    styles.add(
        ParagraphStyle(
            "MCQOption",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            alignment=TA_LEFT,
        )
    )

    # Header Metadata Text
    styles.add(
        ParagraphStyle(
            "MetaText",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=12,
        )
    )

    return styles


def generate_test_pdf(
    test_data: Class9TestSchema,
    output_path: str | None = None,
    include_answer_key: bool = True,
) -> BytesIO | str:
    """Renders a Class9TestSchema Pydantic object into a formatted PDF exam.

    Args:
        test_data: The validated Pydantic test schema instance.
        output_path: Optional file path to save PDF directly. If None, returns BytesIO.
        include_answer_key: Whether to append a teacher answer key page at the end.

    Returns:
        FilePath string if output_path provided, else BytesIO buffer.
    """
    buffer = BytesIO() if output_path is None else output_path

    # Page Setup (A4 with 0.5 inch / 36 pt margins)
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36,
    )

    styles = create_exam_styles()
    story = []

    # -------------------------------------------------------------------------
    # 1. EXAM HEADER & STUDENT INFO BOX
    # -------------------------------------------------------------------------
    story.append(Paragraph(escape_for_paragraph(test_data.test_title.upper()), styles["ExamHeader"]))
    story.append(Spacer(1, 8))

    # Calculate dynamic total marks to guarantee consistency with edited questions
    computed_marks = (
        len(test_data.mcqs) * 1
        + sum(sq.marks for sq in test_data.short_questions)
        + sum(lq.marks for lq in test_data.long_questions)
    )
    total_marks_val = computed_marks if computed_marks > 0 else test_data.total_marks

    # Meta Table: Subject, Time, Total Marks
    grade_val = getattr(test_data, "grade", 9) or 9
    meta_info = [
        [
            Paragraph(f"<b>Subject:</b> {escape_for_paragraph(test_data.subject)}", styles["MetaText"]),
            Paragraph(f"<b>Class:</b> Grade {grade_val}", styles["MetaText"]),
            Paragraph(f"<b>Time Allowed:</b> {escape_for_paragraph(test_data.time_allowed)}", styles["MetaText"]),
            Paragraph(f"<b>Total Marks:</b> {total_marks_val}", styles["MetaText"]),
        ]
    ]
    meta_table = Table(meta_info, colWidths=[130, 90, 150, 120])
    meta_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#EDF2F7")),
                ("PADDING", (0, 0), (-1, -1), 6),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
            ]
        )
    )
    story.append(meta_table)
    story.append(Spacer(1, 8))

    # Student Details Fill-in Line
    student_info = [
        [
            Paragraph("<b>Student Name:</b> ___________________________", styles["MetaText"]),
            Paragraph("<b>Roll No:</b> _____________", styles["MetaText"]),
            Paragraph("<b>Date:</b> _____________", styles["MetaText"]),
        ]
    ]
    student_table = Table(student_info, colWidths=[240, 140, 140])
    student_table.setStyle(
        TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE")])
    )
    story.append(student_table)
    story.append(Spacer(1, 6))

    # Instructions Section
    if test_data.instructions:
        cleaned_instructions = [escape_for_paragraph(ins) for ins in test_data.instructions]
        instructions_text = "<b>Instructions:</b> " + " | ".join(cleaned_instructions)
        story.append(Paragraph(instructions_text, styles["QuestionBody"]))

    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#2B6CB0"), spaceBefore=6, spaceAfter=10))

    # -------------------------------------------------------------------------
    # 2. SECTION A: MULTIPLE CHOICE QUESTIONS (MCQs)
    # -------------------------------------------------------------------------
    if test_data.mcqs:
        mcq_header = f"SECTION A: MULTIPLE CHOICE QUESTIONS ({len(test_data.mcqs)} Marks)"
        story.append(Paragraph(escape_for_paragraph(mcq_header), styles["SectionHeader"]))

        for mcq in test_data.mcqs:
            q_text = f"<b>Q{mcq.question_number}.</b> {escape_for_paragraph(mcq.question)}"
            
            # Format 4 options in a 2x2 grid table for clean alignment
            opt_a = escape_for_paragraph(mcq.options[0] if len(mcq.options) > 0 else "")
            opt_b = escape_for_paragraph(mcq.options[1] if len(mcq.options) > 1 else "")
            opt_c = escape_for_paragraph(mcq.options[2] if len(mcq.options) > 2 else "")
            opt_d = escape_for_paragraph(mcq.options[3] if len(mcq.options) > 3 else "")
            opts_data = [
                [
                    Paragraph(opt_a, styles["MCQOption"]),
                    Paragraph(opt_b, styles["MCQOption"]),
                ],
                [
                    Paragraph(opt_c, styles["MCQOption"]),
                    Paragraph(opt_d, styles["MCQOption"]),
                ],
            ]
            opts_table = Table(opts_data, colWidths=[250, 250])
            opts_table.setStyle(
                TableStyle(
                    [
                        ("LEFTPADDING", (0, 0), (-1, -1), 12),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
                        ("TOPPADDING", (0, 0), (-1, -1), 2),
                    ]
                )
            )

            # Keep question + options together to prevent page breaks mid-question
            story.append(
                KeepTogether(
                    [
                        Paragraph(q_text, styles["QuestionBody"]),
                        opts_table,
                        Spacer(1, 6),
                    ]
                )
            )

        story.append(Spacer(1, 6))

    # -------------------------------------------------------------------------
    # 3. SECTION B: SHORT ANSWER QUESTIONS
    # -------------------------------------------------------------------------
    if test_data.short_questions:
        short_total = sum(sq.marks for sq in test_data.short_questions)
        short_header = f"SECTION B: SHORT ANSWER QUESTIONS ({short_total} Marks)"
        story.append(Paragraph(escape_for_paragraph(short_header), styles["SectionHeader"]))

        for sq in test_data.short_questions:
            sq_text = f"<b>Q{sq.question_number}.</b> {escape_for_paragraph(sq.question)} <font color='#718096'>[{sq.marks} Marks]</font>"
            story.append(
                KeepTogether(
                    [
                        Paragraph(sq_text, styles["QuestionBody"]),
                        Spacer(1, 4),
                    ]
                )
            )

        story.append(Spacer(1, 6))

    # -------------------------------------------------------------------------
    # 4. SECTION C: LONG / ESSAY QUESTIONS
    # -------------------------------------------------------------------------
    if test_data.long_questions:
        long_total = sum(lq.marks for lq in test_data.long_questions)
        long_header = f"SECTION C: LONG / ANALYTICAL QUESTIONS ({long_total} Marks)"
        story.append(Paragraph(escape_for_paragraph(long_header), styles["SectionHeader"]))

        for lq in test_data.long_questions:
            lq_text = f"<b>Q{lq.question_number}.</b> {escape_for_paragraph(lq.question)} <font color='#718096'>[{lq.marks} Marks]</font>"
            story.append(
                KeepTogether(
                    [
                        Paragraph(lq_text, styles["QuestionBody"]),
                        Spacer(1, 6),
                    ]
                )
            )

    # -------------------------------------------------------------------------
    # 5. TEACHER ANSWER KEY (APPENDIX)
    # -------------------------------------------------------------------------
    if include_answer_key and test_data.mcqs:
        story.append(PageBreak())
        story.append(Paragraph("TEACHER ANSWER KEY & VERIFICATION", styles["ExamHeader"]))
        story.append(Spacer(1, 10))

        key_data = [["Q#", "Correct Option", "Textbook Excerpt / Reference"]]
        for mcq in test_data.mcqs:
            key_data.append(
                [
                    str(mcq.question_number),
                    mcq.correct_option,
                    Paragraph(escape_for_paragraph(mcq.textbook_reference), styles["MCQOption"]),
                ]
            )

        key_table = Table(key_data, colWidths=[40, 90, 390])
        key_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2B6CB0")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("ALIGN", (0, 0), (1, -1), "CENTER"),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                    ("PADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        story.append(key_table)

    # Build PDF
    doc.build(story)

    if output_path is None:
        buffer.seek(0)
        return buffer
    return output_path