#!/usr/bin/env python3
"""
Generates an authentic sample exam paper PNG asset for ExamCraft documentation.
Synthesizes a Board of Intermediate and Secondary Education (BISE) standard
Class 9 Mathematics assessment paper for Chapter 1 (Matrices and Determinants)
and renders it to a crisp 150 DPI PNG using ReportLab and PyMuPDF.
"""

import sys
import os
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(backend_dir))

from schemas.exam_schema import Class9TestSchema, MCQItem, ShortQuestionItem, LongQuestionItem
from services.pdf_generator import generate_test_pdf
import fitz  # PyMuPDF


def main():
    repo_root = Path(__file__).resolve().parent.parent
    assets_dir = repo_root / "docs" / "assets"
    assets_dir.mkdir(parents=True, exist_ok=True)
    output_png = assets_dir / "sample_exam_paper.png"

    sample_test = Class9TestSchema(
        test_title="Class 9 Mathematics - Chapter 1: Matrices and Determinants",
        subject="Mathematics",
        grade=9,
        chapter_or_topic="Chapter 1: Matrices and Determinants",
        total_marks=25,
        time_allowed="45 Minutes",
        instructions=[
            "Attempt all questions in Section A and Section B.",
            "Write answers clearly and show all intermediate working steps for numerical problems.",
            "Calculators are not permitted for arithmetic operations in Section A.",
        ],
        mcqs=[
            MCQItem(
                question_number=1,
                question="The order of matrix [2  1] is:",
                options=["2-by-1", "1-by-2", "1-by-1", "2-by-2"],
                correct_option="B",
                textbook_reference="PCTB Class 9 Mathematics, Page 2, Section 1.1: Order of a Matrix",
                chunk_id=1,
                cited_quote="A matrix with one row and two columns has order 1-by-2."
            ),
            MCQItem(
                question_number=2,
                question="If matrix A is singular, then its determinant |A| is equal to:",
                options=["1", "-1", "0", "Undefined"],
                correct_option="C",
                textbook_reference="PCTB Class 9 Mathematics, Page 17, Section 1.5.2: Singular and Non-Singular Matrices",
                chunk_id=4,
                cited_quote="A square matrix A is called singular if the determinant of A is equal to zero, i.e., det(A) = 0."
            ),
            MCQItem(
                question_number=3,
                question="The additive identity of matrices is represented by:",
                options=["Identity Matrix (I)", "Zero/Null Matrix (O)", "Diagonal Matrix", "Scalar Matrix"],
                correct_option="B",
                textbook_reference="PCTB Class 9 Mathematics, Page 11, Section 1.3.3: Additive Identity of a Matrix",
                chunk_id=3,
                cited_quote="Let A and B be matrices of same order. If A + B = A = B + A, then matrix B is called additive identity."
            ),
            MCQItem(
                question_number=4,
                question="Which of the following operations is NOT commutative for matrices in general?",
                options=["Matrix Addition", "Scalar Multiplication", "Matrix Multiplication", "Matrix Subtraction"],
                correct_option="C",
                textbook_reference="PCTB Class 9 Mathematics, Page 14, Section 1.4.3: Commutative Law of Multiplication",
                chunk_id=5,
                cited_quote="Commutative law under multiplication in matrices does not hold in general, i.e., AB ≠ BA."
            ),
        ],
        short_questions=[
            ShortQuestionItem(
                question_number=1,
                question="Find the transpose of matrix B = [[1, 2], [3, 4], [5, 6]] and state its order.",
                marks=2,
                textbook_reference="PCTB Class 9 Mathematics, Page 6, Exercise 1.2, Q5",
                chunk_id=2,
                cited_quote="A matrix obtained by changing the rows into columns or columns into rows is called transpose."
            ),
            ShortQuestionItem(
                question_number=2,
                question="Given matrix M = [[2, -1], [3, 4]], calculate the determinant det(M) and state whether M is singular.",
                marks=2,
                textbook_reference="PCTB Class 9 Mathematics, Page 18, Section 1.5.1",
                chunk_id=4,
                cited_quote="For a 2-by-2 matrix [[a, b], [c, d]], det(M) = ad - bc."
            ),
            ShortQuestionItem(
                question_number=3,
                question="Define a Scalar Matrix and provide one concrete 2-by-2 example.",
                marks=2,
                textbook_reference="PCTB Class 9 Mathematics, Page 8, Section 1.2: Types of Matrices",
                chunk_id=2,
                cited_quote="A diagonal matrix is called a scalar matrix if all the diagonal entries are same and non-zero."
            ),
        ],
        long_questions=[
            LongQuestionItem(
                question_number=1,
                question="Solve the following system of linear equations using Cramer's Rule:\n   2x - 2y = 4\n   3x + 2y = 6",
                marks=5,
                textbook_reference="PCTB Class 9 Mathematics, Page 24, Section 1.6: Application of Matrices, Exercise 1.6",
                chunk_id=6,
                cited_quote="Cramer's Rule states that x = det(Ax) / det(A) and y = det(Ay) / det(A)."
            ),
        ],
    )

    print("Generating exam PDF in memory...")
    pdf_buffer = generate_test_pdf(sample_test, output_path=None, include_answer_key=True)
    pdf_bytes = pdf_buffer.getvalue()

    print("Opening PDF with PyMuPDF...")
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    print(f"Total pages rendered: {len(doc)}")

    # Extract Page 1 (first page)
    page1 = doc[0]
    # Render at 150 DPI for crisp web display (standard is 72 DPI, so 150/72 ≈ 2.08 scale)
    zoom = 150 / 72.0
    mat = fitz.Matrix(zoom, zoom)
    pix = page1.get_pixmap(matrix=mat, alpha=False)

    pix.save(str(output_png))
    print(f"Successfully saved sample exam paper to: {output_png}")
    print(f"Dimensions: {pix.width}x{pix.height} pixels, size: {os.path.getsize(output_png) / 1024:.1f} KB")


if __name__ == "__main__":
    main()
