# schemas/exam_schema.py

from typing import List
from pydantic import BaseModel, Field, field_validator


class MCQItem(BaseModel):
    question_number: int = Field(description="Sequential question number, e.g., 1")
    question: str = Field(description="The MCQ question stem")
    options: List[str] = Field(
        description="Exactly 4 options formatted as ['A) ...', 'B) ...', 'C) ...', 'D) ...']"
    )
    correct_option: str = Field(description="The correct letter choice: A, B, C, or D")
    textbook_reference: str = Field(
        description="Exact quote or concept excerpt from the context verifying this answer"
    )

    @field_validator("options")
    def validate_options_count(cls, v: List[str]) -> List[str]:
        if len(v) != 4:
            raise ValueError("MCQs must have exactly 4 choices.")
        return v


class ShortQuestionItem(BaseModel):
    question_number: int = Field(description="Sequential question number")
    question: str = Field(description="Concise question requiring a 2-4 line answer")
    marks: int = Field(default=2, description="Marks allocated for this short question")


class LongQuestionItem(BaseModel):
    question_number: int = Field(description="Sequential question number")
    question: str = Field(
        description="Detailed numerical, analytical, or descriptive question"
    )
    marks: int = Field(default=5, description="Marks allocated for this long question")


class Class9TestSchema(BaseModel):
    test_title: str = Field(description="Title, e.g., 'Class 9 Physics - Chapter 3 Test'")
    subject: str = Field(description="Subject name, e.g., Physics")
    grade: int = Field(default=9, description="Target educational class level: 9, 10, 11, or 12")
    chapter_or_topic: str = Field(description="Chapter name or section covered")
    total_marks: int = Field(description="Sum of marks across all sections")
    time_allowed: str = Field(default="45 Minutes", description="Time limit for the test")
    instructions: List[str] = Field(
        default=[
            "Attempt all questions.",
            "Write neatly and draw diagrams where necessary."
        ],
        description="General instructions for students"
    )
    mcqs: List[MCQItem] = Field(description="Section A: Multiple Choice Questions")
    short_questions: List[ShortQuestionItem] = Field(description="Section B: Short Answer Questions")
    long_questions: List[LongQuestionItem] = Field(description="Section C: Long / Essay Questions")


# Semantic aliases for question items
MCQQuestion = MCQItem
ShortQuestion = ShortQuestionItem
LongQuestion = LongQuestionItem


class SectionAResponse(BaseModel):
    questions: List[MCQItem] = Field(
        default_factory=list,
        description="Section A: Multiple Choice Questions"
    )

    @property
    def mcqs(self) -> List[MCQItem]:
        return self.questions


class SectionBResponse(BaseModel):
    questions: List[ShortQuestionItem] = Field(
        default_factory=list,
        description="Section B: Short Answer Questions"
    )

    @property
    def short_questions(self) -> List[ShortQuestionItem]:
        return self.questions


class SectionCResponse(BaseModel):
    questions: List[LongQuestionItem] = Field(
        default_factory=list,
        description="Section C: Long / Essay Questions"
    )

    @property
    def long_questions(self) -> List[LongQuestionItem]:
        return self.questions


# Semantic alias for multi-class support (Classes 9, 10, 11, 12).
# Maintained alongside Class9TestSchema for 100% backward compatibility.
ExamTestSchema = Class9TestSchema
