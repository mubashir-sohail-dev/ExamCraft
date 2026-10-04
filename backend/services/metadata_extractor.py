"""
Reusable metadata extraction layer.
Pipeline: PDF → Text Extraction → MetadataExtractor → Chunking → Vector Storage

New metadata types can be added by creating new ExtractionRule subclasses
without changing existing extraction logic.
"""
import re
import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class TextMetadata:
    """Extracted structural metadata from a page of text."""
    chapter: Optional[str] = None
    exercise: Optional[str] = None
    section: Optional[str] = None
    topic: Optional[str] = None


class ExtractionRule(ABC):
    """Base class for metadata extraction rules."""
    
    @property
    @abstractmethod
    def field_name(self) -> str:
        """The metadata field this rule populates."""
        ...
    
    @abstractmethod
    def extract(self, text: str) -> Optional[str]:
        """Extract metadata value from text. Returns None if not found."""
        ...


class ExerciseExtractionRule(ExtractionRule):
    """Detects exercise labels like 'Exercise 1.1', 'Review Exercise', 'Miscellaneous Exercise'."""
    
    PATTERNS = [
        re.compile(r'(?i)\b(Exercise\s*[\r\n\s]*\d+(?:\.\d+)?)\b'),
        re.compile(r'(?i)\b(Review\s*[\r\n\s]*Exercise(?:\s*[\r\n\s]*\d+(?:\.\d+)?)?)\b'),
        re.compile(r'(?i)\b(Miscellaneous\s*[\r\n\s]*Exercise(?:\s*[\r\n\s]*\d+(?:\.\d+)?)?)\b'),
    ]
    
    @property
    def field_name(self) -> str:
        return "exercise"
    
    def extract(self, text: str) -> Optional[str]:
        for pattern in self.PATTERNS:
            match = pattern.search(text)
            if match:
                clean_label = re.sub(r'[\r\n\s]+', ' ', match.group(1)).strip().title()
                return clean_label
        return None


class SectionExtractionRule(ExtractionRule):
    """Detects section labels like 'Section 2.3'. Internal use only."""
    
    PATTERNS = [
        re.compile(r'(?i)\b(Section\s+\d+(?:\.\d+)?)\b'),
    ]
    
    @property
    def field_name(self) -> str:
        return "section"
    
    def extract(self, text: str) -> Optional[str]:
        for pattern in self.PATTERNS:
            match = pattern.search(text)
            if match:
                return match.group(1).strip()
        return None


class TopicExtractionRule(ExtractionRule):
    """Detects sub-topic labels. Internal use only."""
    
    PATTERNS = [
        re.compile(r'(?i)\b(Topic\s+\d+(?:\.\d+)?)\b'),
    ]
    
    @property
    def field_name(self) -> str:
        return "topic"
    
    def extract(self, text: str) -> Optional[str]:
        for pattern in self.PATTERNS:
            match = pattern.search(text)
            if match:
                return match.group(1).strip()
        return None


class MetadataExtractor:
    """
    Stateful extractor that tracks current metadata context across pages.
    Runs the same extraction rules regardless of text source (native or OCR).
    
    IMPORTANT: Extraction rules (Exercise, Section, Topic) only run for Mathematics.
    Non-Math subjects maintain an empty rule set for a clean chapter-only schema.
    """
    
    def __init__(self, subject: str):
        self.subject = subject
        self._current: dict[str, Optional[str]] = {
            "exercise": None,
            "section": None,
            "topic": None,
        }
        
        # Build rule set based on subject
        self._rules: list[ExtractionRule] = []
        if str(subject).strip().lower() in ("mathematics", "math"):
            self._rules.append(ExerciseExtractionRule())
            self._rules.append(SectionExtractionRule())
            self._rules.append(TopicExtractionRule())
        
        self._all_exercises: set[str] = set()
        self._all_chapters: set[str] = set()
    
    def extract_from_text(self, text: str) -> TextMetadata:
        """
        Extract metadata from a page of text.
        Updates internal state and returns detected metadata.
        """
        metadata = TextMetadata()
        
        for rule in self._rules:
            result = rule.extract(text)
            if result is not None:
                setattr(metadata, rule.field_name, result)
                self._current[rule.field_name] = result
                logger.info("Detected %s: '%s'", rule.field_name, result)
        
        # Carry forward current state for fields not detected on this page
        for field_name, current_value in self._current.items():
            if getattr(metadata, field_name) is None and current_value is not None:
                setattr(metadata, field_name, current_value)
                
        if metadata.exercise:
            self._all_exercises.add(metadata.exercise)
            
        return metadata
    
    def track_chapter(self, chapter: str):
        """Track a detected chapter for upload summary."""
        self._all_chapters.add(chapter)
    
    def reset_for_new_chapter(self):
        """Reset exercise/section/topic tracking when a new chapter starts."""
        self._current = {
            "exercise": None,
            "section": None,
            "topic": None,
        }
    
    @property
    def detected_exercises(self) -> set[str]:
        """Track all unique exercises detected across the document (for summary)."""
        return self._all_exercises

    @property
    def summary(self) -> dict:
        """Return extraction summary for upload response."""
        return {
            "chapters_detected": len(self._all_chapters),
            "exercises_detected": len(self._all_exercises),
        }
