# schemas/request_schemas.py
"""
ExamCraft AI - API Request Schemas
Strongly typed Pydantic models for client request payloads.
"""
from pydantic import BaseModel, Field
from schemas.exam_enums import SubjectEnum, RetrievalModeEnum, DifficultyEnum
from schemas.exam_schema import Class9TestSchema


class TestGenerationRequest(BaseModel):
    """Input payload for generating a draft examination test JSON."""
    subject: SubjectEnum = Field(
        ...,
        json_schema_extra={"example": "Chemistry"},
        description="Subject for the examination paper"
    )
    grade: int = Field(
        default=9,
        ge=9,
        le=12,
        json_schema_extra={"example": 9},
        description="Target educational class/grade (9, 10, 11, or 12)"
    )
    chapter_name: str = Field(
        ...,
        json_schema_extra={"example": "Chapter 3"},
        description="Chapter identifier or name"
    )
    test_type: RetrievalModeEnum = Field(
        ...,
        json_schema_extra={"example": "topic"},
        description="Retrieval mode: 'full_chapter' or 'topic'"
    )
    topic_query: str | None = Field(
        default=None,
        json_schema_extra={"example": "Newton's Laws of Motion"},
        description="Specific topic query required when test_type is 'topic'"
    )
    mcq_count: int = Field(
        default=5,
        ge=1,
        le=20,
        description="Number of Multiple Choice Questions (1 mark each)"
    )
    short_count: int = Field(
        default=3,
        ge=0,
        le=10,
        description="Number of Short Answer Questions (2 marks each)"
    )
    long_count: int = Field(
        default=1,
        ge=0,
        le=5,
        description="Number of Long / Essay Questions (5 marks each)"
    )
    include_answer_key: bool = Field(
        default=True,
        description="Whether to include answer key metadata"
    )
    exercise: str | None = Field(
        default=None,
        description="Optional exercise identifier (e.g., 'Exercise 1.1') for Mathematics textbooks"
    )
    difficulty: DifficultyEnum = Field(
        default=DifficultyEnum.MIXED,
        description="Bloom's taxonomy cognitive difficulty level ('easy', 'medium', 'hard', 'mixed')"
    )
    generation_instruction: str | None = Field(
        default=None,
        max_length=2000,
        description="Optional teacher instruction to guide test generation"
    )


class PDFRenderRequest(BaseModel):
    """Input payload for rendering approved Class9TestSchema JSON into a PDF."""
    test_data: Class9TestSchema = Field(
        ...,
        description="Approved structured test JSON object"
    )
    include_answer_key: bool = Field(
        default=True,
        description="Whether to append the teacher answer key page to the rendered PDF"
    )
