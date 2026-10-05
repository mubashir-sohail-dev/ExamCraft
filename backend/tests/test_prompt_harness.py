import pytest
from services.prompt_builder import PromptBuilder

def test_basic_prompt_construction():
    subject = "Math"
    chapter_or_topic = "Chapter 1"
    mcq_count = 5
    short_count = 3
    long_count = 1
    context = "Here is some context."
    
    messages = PromptBuilder.build(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        mcq_count=mcq_count,
        short_count=short_count,
        long_count=long_count,
        context=context
    )
    
    assert len(messages) == 2
    assert messages[0]["role"] == "system"
    assert "You are an expert Class 9 Academic Examination Setter" in messages[0]["content"]
    
    assert messages[1]["role"] == "user"
    user_content = messages[1]["content"]
    assert "Generate a Class 9 Math test for Chapter 1." in user_content
    assert "<textbook_context>\nHere is some context.\n</textbook_context>" in user_content
    assert "### EXERCISE FOCUS:" not in user_content
    assert "### ADDITIONAL TEACHER INSTRUCTIONS:" not in user_content

def test_optional_fields():
    subject = "Math"
    chapter_or_topic = "Chapter 1"
    mcq_count = 5
    short_count = 3
    long_count = 1
    context = "Here is some context."
    exercise = "Exercise 1.1"
    generation_instruction = "Make it very hard."
    
    messages = PromptBuilder.build(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        mcq_count=mcq_count,
        short_count=short_count,
        long_count=long_count,
        context=context,
        exercise=exercise,
        generation_instruction=generation_instruction
    )
    
    user_content = messages[1]["content"]
    assert "### EXERCISE FOCUS:" in user_content
    assert "Exercise 1.1" in user_content
    assert "### ADDITIONAL TEACHER INSTRUCTIONS:" in user_content
    assert "Make it very hard." in user_content

def test_exact_ordering():
    subject = "Math"
    chapter_or_topic = "Chapter 1"
    mcq_count = 5
    short_count = 3
    long_count = 1
    context = "Here is some context."
    exercise = "Exercise 1.1"
    generation_instruction = "Make it very hard."
    
    messages = PromptBuilder.build(
        subject=subject,
        chapter_or_topic=chapter_or_topic,
        mcq_count=mcq_count,
        short_count=short_count,
        long_count=long_count,
        context=context,
        exercise=exercise,
        generation_instruction=generation_instruction
    )
    
    user_content = messages[1]["content"]
    
    # Check ordering
    req_pos = user_content.find("### TEST REQUIREMENTS:")
    constraints_pos = user_content.find("### STRICT RULES FOR ACCURACY")
    diff_pos = user_content.find("### COGNITIVE DIFFICULTY LEVEL:")
    exercise_pos = user_content.find("### EXERCISE FOCUS:")
    context_pos = user_content.rfind("<textbook_context>")
    teacher_pos = user_content.find("### ADDITIONAL TEACHER INSTRUCTIONS:")
    format_pos = user_content.find("### FORMATTING & OUTPUT RULES:")
    
    assert req_pos != -1
    assert constraints_pos != -1
    assert diff_pos != -1
    assert exercise_pos != -1
    assert context_pos != -1
    assert teacher_pos != -1
    assert format_pos != -1
    
    assert req_pos < constraints_pos < diff_pos < exercise_pos < context_pos < teacher_pos < format_pos


def test_section_a_prompt_construction():
    """Tests Section A specialized prompt builder."""
    messages = PromptBuilder.build_section_a_prompt(
        subject="Chemistry",
        chapter_or_topic="Chapter 1",
        count=5,
        context="Sample context",
        grade=9,
        difficulty="hard"
    )
    assert len(messages) == 2
    assert "Multiple Choice Questions (Section A)" in messages[0]["content"]
    assert "### SECTION A REQUIREMENTS:" in messages[1]["content"]
    assert "Generate exactly 5 Multiple Choice Questions" in messages[1]["content"]
    assert "SectionAResponse JSON schema" in messages[1]["content"]


def test_section_b_prompt_construction():
    """Tests Section B specialized prompt builder."""
    messages = PromptBuilder.build_section_b_prompt(
        subject="Physics",
        chapter_or_topic="Chapter 2",
        count=3,
        context="Sample context",
        grade=10,
        difficulty="medium"
    )
    assert len(messages) == 2
    assert "Short Answer Questions (Section B)" in messages[0]["content"]
    assert "### SECTION B REQUIREMENTS:" in messages[1]["content"]
    assert "Generate exactly 3 Short Answer Questions (2 marks each)" in messages[1]["content"]
    assert "SectionBResponse JSON schema" in messages[1]["content"]


def test_section_c_prompt_construction():
    """Tests Section C specialized prompt builder."""
    messages = PromptBuilder.build_section_c_prompt(
        subject="Biology",
        chapter_or_topic="Chapter 3",
        count=2,
        context="Sample context",
        grade=11,
        difficulty="easy"
    )
    assert len(messages) == 2
    assert "Long / Essay Questions (Section C)" in messages[0]["content"]
    assert "### SECTION C REQUIREMENTS:" in messages[1]["content"]
    assert "Generate exactly 2 Long / Essay Questions (5 marks each)" in messages[1]["content"]
    assert "SectionCResponse JSON schema" in messages[1]["content"]
