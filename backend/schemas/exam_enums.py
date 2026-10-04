# schemas/exam_enums.py
"""
ExamCraft AI - Domain Enumerations
Defines strongly-typed enums for curriculum subjects, retrieval modes, and Bloom's cognitive difficulty levels.
"""
from enum import Enum


class SubjectEnum(str, Enum):
    """Supported secondary & higher secondary curriculum subjects."""
    CHEMISTRY = "Chemistry"
    PHYSICS = "Physics"
    MATHEMATICS = "Mathematics"
    BIOLOGY = "Biology"
    COMPUTER_SCIENCE = "Computer Science"


class RetrievalModeEnum(str, Enum):
    """Vector database retrieval modes."""
    FULL_CHAPTER = "full_chapter"
    TOPIC = "topic"


class DifficultyEnum(str, Enum):
    """Cognitive difficulty levels aligned with Bloom's Taxonomy."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    MIXED = "mixed"
