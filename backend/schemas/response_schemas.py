# schemas/response_schemas.py
"""
ExamCraft AI - API Response Schemas
Strongly typed Pydantic models for API responses.
"""
from typing import List, Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Response model for system health check endpoint."""
    status: str = Field(json_schema_extra={"example": "ok"}, description="Overall health status of the API")
    qdrant_connected: bool = Field(json_schema_extra={"example": True}, description="Connectivity status to Qdrant Cloud")
    version: str = Field(json_schema_extra={"example": "1.0.0"}, description="Application version")
    environment: str = Field(default="production", json_schema_extra={"example": "production"}, description="Running environment")
    uptime_seconds: float = Field(default=0.0, json_schema_extra={"example": 124.5}, description="System uptime in seconds")
    timestamp: str = Field(default="", json_schema_extra={"example": "2026-07-28T02:00:00Z"}, description="Current UTC timestamp")
    qdrant_latency_ms: Optional[float] = Field(default=0.0, json_schema_extra={"example": 12.4}, description="Qdrant ping latency in ms")
    collection_exists: bool = Field(default=True, json_schema_extra={"example": True}, description="Whether default collection exists")
    llm_available: bool = Field(default=True, json_schema_extra={"example": True}, description="LLM service configuration status")


class SubjectListResponse(BaseModel):
    """Response model listing supported subjects."""
    subjects: List[str] = Field(
        json_schema_extra={"example": ["Chemistry", "Physics", "Mathematics"]},
        description="List of available subjects"
    )


class ChapterListResponse(BaseModel):
    """Response model listing available chapters for a subject."""
    subject: str = Field(json_schema_extra={"example": "Chemistry"}, description="Subject queried")
    chapters: List[str] = Field(
        json_schema_extra={"example": ["Chapter 1", "Chapter 2", "Chapter 3"]},
        description="List of chapter names retrieved from index"
    )


class ChapterMetadataResponse(BaseModel):
    subject: str
    chapter: str
    exercises: List[str] = []
    sections: List[str] = []
    topics: List[str] = []


class TextbookUploadResponse(BaseModel):
    """Response model for admin textbook upload."""
    status: str = Field(json_schema_extra={"example": "success"}, description="Upload status")
    message: str = Field(
        json_schema_extra={"example": "Successfully processed Chemistry_Grade9.pdf"},
        description="Detailed message"
    )
    chunks_indexed: int = Field(json_schema_extra={"example": 145}, description="Number of text chunks stored in vector database")
    chapters_detected: int = 0
    exercises_detected: int = 0
