from typing import List
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """Centralized application settings loaded from environment variables."""

    # Qdrant Vector Database
    QDRANT_URL: str = Field(
        default="http://localhost:6333",
        description="Qdrant Cloud or local cluster URL"
    )
    QDRANT_API_KEY: str | None = Field(
        default=None,
        description="Qdrant API Key for Cloud authentication"
    )
    COLLECTION_NAME: str = Field(
        default="class_9_textbooks",
        description="Default Qdrant collection name for textbook vectors"
    )
    QDRANT_BATCH_SIZE: int = Field(
        default=32,
        description="Batch size for uploading chunks to Qdrant"
    )

    # LLM Settings (OmniRoute OpenAI-compatible gateway)
    LLM_BASE_URL: str = Field(
        default="https://omni.ai-vision.studio/v1",
        description="Base URL for OmniRoute OpenAI-compatible LLM endpoint"
    )
    LLM_API_KEY: str = Field(
        default="",
        description="API Key for LLM provider (e.g. Gemini API Key)"
    )
    GEMINI_API_KEY: str | None = Field(
        default=None,
        description="Direct Google Gemini API Key for OCR and multimodal vision"
    )
    LLM_MODEL_NAME: str = Field(
        default="gemini-3.8-flash",
        description="LLM Model identifier"
    )
    MAX_CONTEXT_CHARS: int = Field(
        default=12000,
        description="Maximum characters allowed in retrieved context for LLM generation"
    )

    # FastEmbed Embedding Models
    DENSE_MODEL_NAME: str = Field(
        default="BAAI/bge-small-en-v1.5",
        description="FastEmbed dense embedding model"
    )
    SPARSE_MODEL_NAME: str = Field(
        default="Qdrant/bm25",
        description="FastEmbed sparse embedding model"
    )

    # Storage & Upload Configuration
    UPLOAD_DIR: str = Field(
        default="temp_uploads",
        description="Directory for temporary uploaded files"
    )
    PDF_TEMP_DIRECTORY: str = Field(
        default="temp_uploads",
        description="Directory for temporary uploaded PDF files (alias to UPLOAD_DIR)"
    )
    MAX_UPLOAD_SIZE_MB: int = Field(
        default=1000,
        description="Maximum allowed file size for textbook PDF upload in MB"
    )

    # Application Metadata & Logging
    APP_TITLE: str = "ExamCraft AI – Automated Test Generator"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = (
        "Zero-hallucination examination paper generator powered by RAG and FastAPI."
    )
    LOG_LEVEL: str = Field(
        default="INFO",
        description="Application logging level (DEBUG, INFO, WARNING, ERROR)"
    )

    # Security & API Authentication
    API_KEY: str = Field(
        default="examcraft-secret-key-2026",
        description="API Key required for client access to generation, rendering, and metadata"
    )
    ADMIN_API_KEY: str = Field(
        default="examcraft-admin-key-2026",
        description="Admin API Key required for uploading and indexing textbooks"
    )
    ENABLE_AUTH: bool = Field(
        default=True,
        description="Global switch to enforce API key authentication"
    )
    ALLOWED_ORIGINS: List[str] = Field(
        default=["*"],
        description="Allowed CORS origins list (e.g. ['http://localhost:3000', 'https://examcraft.com'])"
    )

    # Supported Subjects List (can be extended without architectural changes)
    SUPPORTED_SUBJECTS: List[str] = [
        "Chemistry",
        "Physics",
        "Mathematics",
        "Biology",
        "Computer Science",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
