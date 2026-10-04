class PromptBuilder:
    """Modular prompt assembly for test generation with concurrent section support."""
    
    @classmethod
    def _parse_section_args(cls, section_type: str, *args, **kwargs) -> dict:
        """Helper to parse either a request object + context or individual kwargs."""
        if args and hasattr(args[0], "subject"):
            req = args[0]
            context = args[1] if len(args) > 1 else kwargs.get("context", "")
            subject = req.subject.value if hasattr(req.subject, "value") else str(req.subject)
            if hasattr(req, "test_type"):
                tt_val = req.test_type.value if hasattr(req.test_type, "value") else str(req.test_type)
                chapter_or_topic = req.topic_query if tt_val == "topic" and req.topic_query else req.chapter_name
            else:
                chapter_or_topic = getattr(req, "chapter_name", "General")
            grade = getattr(req, "grade", 9)
            exercise = getattr(req, "exercise", None)
            generation_instruction = getattr(req, "generation_instruction", None)
            diff = getattr(req, "difficulty", "mixed")
            difficulty = diff.value if hasattr(diff, "value") else str(diff)
            if section_type == "a":
                count = getattr(req, "mcq_count", 5)
            elif section_type == "b":
                count = getattr(req, "short_count", 3)
            else:
                count = getattr(req, "long_count", 1)
        else:
            subject = kwargs.get("subject", args[0] if len(args) > 0 else "General")
            if hasattr(subject, "value"):
                subject = subject.value
            chapter_or_topic = kwargs.get("chapter_or_topic", args[1] if len(args) > 1 else "Chapter 1")
            
            if section_type == "a":
                count = kwargs.get("count", kwargs.get("mcq_count", args[2] if len(args) > 2 else 5))
                context = kwargs.get("context", args[3] if len(args) > 3 else "")
            elif section_type == "b":
                count = kwargs.get("count", kwargs.get("short_count", args[2] if len(args) > 2 else 3))
                context = kwargs.get("context", args[3] if len(args) > 3 else "")
            else:
                count = kwargs.get("count", kwargs.get("long_count", args[2] if len(args) > 2 else 1))
                context = kwargs.get("context", args[3] if len(args) > 3 else "")
                
            grade = kwargs.get("grade", kwargs.get("grade", args[4] if len(args) > 4 else 9))
            exercise = kwargs.get("exercise", args[5] if len(args) > 5 else None)
            generation_instruction = kwargs.get("generation_instruction", args[6] if len(args) > 6 else None)
            diff = kwargs.get("difficulty", args[7] if len(args) > 7 else "mixed")
            difficulty = diff.value if hasattr(diff, "value") else str(diff)

        return {
            "subject": str(subject),
            "chapter_or_topic": str(chapter_or_topic),
            "count": int(count),
            "context": str(context),
            "grade": int(grade),
            "exercise": exercise,
            "generation_instruction": generation_instruction,
            "difficulty": str(difficulty)
        }

    @classmethod
    def build(
        cls, 
        subject: str, 
        chapter_or_topic: str, 
        mcq_count: int, 
        short_count: int, 
        long_count: int, 
        context: str, 
        grade: int = 9,
        exercise: str | None = None, 
        generation_instruction: str | None = None,
        difficulty: str = "mixed"
    ) -> list[dict[str, str]]:
        """
        Monolithic prompt construction. Maintained for full backward compatibility.
        Ensures exact ordering:
        1. System Prompt
        2. Generation requirements
        3. Generation Constraints
        4. Cognitive Difficulty / Bloom's Taxonomy Guidelines
        5. Exercise focus (optional)
        6. Retrieved textbook context
        7. Teacher Instructions (optional)
        8. Output schema / formatting instructions
        """
        system_parts = [cls._get_base_system_prompt(grade)]
        user_parts = []
        
        # 2. Generation requirements
        user_parts.append(cls._get_requirements(subject, chapter_or_topic, mcq_count, short_count, long_count, grade))
        
        # 3. Generation constraints
        user_parts.append(cls._get_generation_constraints())

        # Subject Guidance (if applicable)
        guidance = cls._get_subject_guidance(subject)
        if guidance:
            user_parts.append(guidance)

        # 4. Cognitive Difficulty / Bloom's Taxonomy Guidelines
        user_parts.append(cls._get_difficulty_guidelines(difficulty))
            
        # 5. Exercise focus (optional)
        if exercise and exercise.strip():
            user_parts.append(cls._get_exercise_focus(exercise))
            
        # 6. Retrieved textbook context
        user_parts.append(cls._get_context(context))
        
        # 7. Teacher Generation Instruction (optional)
        if generation_instruction and generation_instruction.strip():
            user_parts.append(cls._get_teacher_instruction(generation_instruction))
        
        # 8. Output schema / formatting instructions
        user_parts.append(cls._get_output_instructions())
        
        return [
            {"role": "system", "content": "\n\n".join(system_parts)},
            {"role": "user", "content": "\n\n".join(user_parts)},
        ]

    @classmethod
    def build_section_a_prompt(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Build specialized prompt for Section A (MCQs)."""
        p = cls._parse_section_args("a", *args, **kwargs)
        return cls._build_section_a_internal(**p)

    @classmethod
    def build_section_a(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Alias for build_section_a_prompt."""
        return cls.build_section_a_prompt(*args, **kwargs)

    @classmethod
    def _build_section_a_internal(
        cls,
        subject: str,
        chapter_or_topic: str,
        count: int,
        context: str,
        grade: int = 9,
        exercise: str | None = None,
        generation_instruction: str | None = None,
        difficulty: str = "mixed"
    ) -> list[dict[str, str]]:
        system_content = f"You are an expert Class {grade} Academic Examination Setter. Your sole objective is to create high-quality Multiple Choice Questions (Section A) strictly grounded in the provided textbook context."
        
        user_parts = [
            f"""Generate Class {grade} {subject} Multiple Choice Questions (Section A) for {chapter_or_topic}.

### SECTION A REQUIREMENTS:
- **MCQs:** Generate exactly {count} Multiple Choice Questions (1 mark each).
- Each question must provide exactly 4 distinct options formatted as ['A) ...', 'B) ...', 'C) ...', 'D) ...'].
- Set 'correct_option' to the single correct choice letter: 'A', 'B', 'C', or 'D'.
- Set 'textbook_reference' to an exact quote or concept excerpt from <textbook_context> verifying this answer.""",
            cls._get_generation_constraints(),
        ]

        guidance = cls._get_subject_guidance(subject)
        if guidance:
            user_parts.append(guidance)

        user_parts.append(cls._get_difficulty_guidelines(difficulty))

        if exercise and exercise.strip():
            user_parts.append(cls._get_exercise_focus(exercise))
            
        user_parts.append(cls._get_context(context))
        
        if generation_instruction and generation_instruction.strip():
            user_parts.append(cls._get_teacher_instruction(generation_instruction))
            
        user_parts.append("""### FORMATTING & OUTPUT RULES:
1. Do not use Unicode subscript or superscript characters (such as ₂, ³, etc.) in chemical formulas or math. Instead, you MUST use standard HTML tags. For example, write H<sub>2</sub>O instead of H₂O, and x<sup>2</sup> instead of x².
2. Output MUST strictly adhere to the SectionAResponse JSON schema containing the list of questions.""")

        return [
            {"role": "system", "content": system_content},
            {"role": "user", "content": "\n\n".join(user_parts)},
        ]

    @classmethod
    def build_section_b_prompt(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Build specialized prompt for Section B (Short Answer Questions)."""
        p = cls._parse_section_args("b", *args, **kwargs)
        return cls._build_section_b_internal(**p)

    @classmethod
    def build_section_b(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Alias for build_section_b_prompt."""
        return cls.build_section_b_prompt(*args, **kwargs)

    @classmethod
    def _build_section_b_internal(
        cls,
        subject: str,
        chapter_or_topic: str,
        count: int,
        context: str,
        grade: int = 9,
        exercise: str | None = None,
        generation_instruction: str | None = None,
        difficulty: str = "mixed"
    ) -> list[dict[str, str]]:
        system_content = f"You are an expert Class {grade} Academic Examination Setter. Your sole objective is to create high-quality Short Answer Questions (Section B) strictly grounded in the provided textbook context."
        
        user_parts = [
            f"""Generate Class {grade} {subject} Short Answer Questions (Section B) for {chapter_or_topic}.

### SECTION B REQUIREMENTS:
- **Short Questions:** Generate exactly {count} Short Answer Questions (2 marks each).
- Each question must be clear, concise, and require a focused 2-4 line / 2-3 sentence answer based on the textbook context.""",
            cls._get_generation_constraints(),
        ]

        guidance = cls._get_subject_guidance(subject)
        if guidance:
            user_parts.append(guidance)

        user_parts.append(cls._get_difficulty_guidelines(difficulty))

        if exercise and exercise.strip():
            user_parts.append(cls._get_exercise_focus(exercise))
            
        user_parts.append(cls._get_context(context))
        
        if generation_instruction and generation_instruction.strip():
            user_parts.append(cls._get_teacher_instruction(generation_instruction))
            
        user_parts.append("""### FORMATTING & OUTPUT RULES:
1. Do not use Unicode subscript or superscript characters (such as ₂, ³, etc.) in chemical formulas or math. Instead, you MUST use standard HTML tags. For example, write H<sub>2</sub>O instead of H₂O, and x<sup>2</sup> instead of x².
2. Output MUST strictly adhere to the SectionBResponse JSON schema containing the list of questions.""")

        return [
            {"role": "system", "content": system_content},
            {"role": "user", "content": "\n\n".join(user_parts)},
        ]

    @classmethod
    def build_section_c_prompt(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Build specialized prompt for Section C (Long / Essay Questions)."""
        p = cls._parse_section_args("c", *args, **kwargs)
        return cls._build_section_c_internal(**p)

    @classmethod
    def build_section_c(cls, *args, **kwargs) -> list[dict[str, str]]:
        """Alias for build_section_c_prompt."""
        return cls.build_section_c_prompt(*args, **kwargs)

    @classmethod
    def _build_section_c_internal(
        cls,
        subject: str,
        chapter_or_topic: str,
        count: int,
        context: str,
        grade: int = 9,
        exercise: str | None = None,
        generation_instruction: str | None = None,
        difficulty: str = "mixed"
    ) -> list[dict[str, str]]:
        system_content = f"You are an expert Class {grade} Academic Examination Setter. Your sole objective is to create high-quality Long / Essay Questions (Section C) strictly grounded in the provided textbook context."
        
        user_parts = [
            f"""Generate Class {grade} {subject} Long / Essay Questions (Section C) for {chapter_or_topic}.

### SECTION C REQUIREMENTS:
- **Long Questions:** Generate exactly {count} Long / Essay Questions (5 marks each).
- Each question must be a detailed numerical, analytical, or descriptive multi-part question based on the textbook context.""",
            cls._get_generation_constraints(),
        ]

        guidance = cls._get_subject_guidance(subject)
        if guidance:
            user_parts.append(guidance)

        user_parts.append(cls._get_difficulty_guidelines(difficulty))

        if exercise and exercise.strip():
            user_parts.append(cls._get_exercise_focus(exercise))
            
        user_parts.append(cls._get_context(context))
        
        if generation_instruction and generation_instruction.strip():
            user_parts.append(cls._get_teacher_instruction(generation_instruction))
            
        user_parts.append("""### FORMATTING & OUTPUT RULES:
1. Do not use Unicode subscript or superscript characters (such as ₂, ³, etc.) in chemical formulas or math. Instead, you MUST use standard HTML tags. For example, write H<sub>2</sub>O instead of H₂O, and x<sup>2</sup> instead of x².
2. Output MUST strictly adhere to the SectionCResponse JSON schema containing the list of questions.""")

        return [
            {"role": "system", "content": system_content},
            {"role": "user", "content": "\n\n".join(user_parts)},
        ]

    @staticmethod
    def _get_base_system_prompt(grade: int = 9) -> str:
        return f"You are an expert Class {grade} Academic Examination Setter. Your sole objective is to create a high-quality test paper strictly grounded in the provided textbook context."

    @staticmethod
    def _get_generation_constraints() -> str:
        return """### STRICT RULES FOR ACCURACY:
1. **100% GROUNDED:** Every single question, MCQ distractor, correct answer, and numeric value MUST be explicitly verified by the text inside <textbook_context>.
2. **NO OUTSIDE KNOWLEDGE:** Do NOT use any knowledge, definitions, formulas, or facts that are not present in <textbook_context>. If a concept is omitted in the context, do NOT test it.
3. **SYLLABUS BOUNDARIES:** Do not make questions harder or broader than what the provided textbook content covers.
4. **INSUFFICIENT CONTEXT FALLBACK:** If the provided context is too brief to generate the requested number of questions, generate ONLY as many valid questions as can be strictly verified."""

    @classmethod
    def _get_subject_guidance(cls, subject: str) -> str:
        """Subject-tailored pedagogical constraints for Pakistani curriculum assessment."""
        sub = str(subject).strip().lower()
        if sub in ("physics",):
            return (
                "### Subject Guidelines (Physics):\n"
                "- Numerical Problems: Include standard SI units (m/s, N, J, W, kg) and explicitly state all given values.\n"
                "- Conceptual Questions: Require students to state the governing physical law/principle before explaining.\n"
                "- Notation: Use standard symbols (e.g., $v_f = v_i + at$, $F = ma$, $W = Fd$)."
            )
        elif sub in ("chemistry",):
            return (
                "### Subject Guidelines (Chemistry):\n"
                "- Chemical Reactions: Ensure all chemical equations are strictly balanced with state symbols (s, l, g, aq).\n"
                "- Terminology: Use authentic IUPAC names and standard molecular formulas.\n"
                "- Definitions & Trends: Emphasize clear definitions (e.g. electronegativity, oxidation state) and periodic trends."
            )
        elif sub in ("biology",):
            return (
                "### Subject Guidelines (Biology):\n"
                "- Anatomical & Cellular Terminology: Use exact scientific terminology for organ systems, cellular organelles, and biological processes.\n"
                "- Structure vs. Function: Frame questions highlighting the relationship between biological structure and physiological function.\n"
                "- Diagram Descriptions: When referencing biological cycles or structures, clearly describe components in the question stem."
            )
        elif sub in ("computer science", "computer_science", "cs"):
            return (
                "### Subject Guidelines (Computer Science):\n"
                "- Code & Syntax: Use clean, standard pseudocode, C/C++ or Python syntax matching the curriculum textbook.\n"
                "- Algorithms & Architecture: Emphasize exact logic, hardware vs software roles, and networking fundamentals.\n"
                "- Output Tracing: Questions involving code snippets must have deterministic, unambiguously traceable execution paths."
            )
        elif sub in ("mathematics", "math"):
            return (
                "### Subject Guidelines (Mathematics):\n"
                "- Mathematical Rigor: Provide exact numerical values or simplified algebraic expressions.\n"
                "- Step-by-Step Clarity: Numerical and algebraic problems must be solvable within standard exam time allocations."
            )
        return ""

    @staticmethod
    def _get_difficulty_guidelines(difficulty: str = "mixed") -> str:
        diff = difficulty.lower().strip() if difficulty else "mixed"
        if diff == "easy":
            return """### COGNITIVE DIFFICULTY LEVEL: EASY (Bloom's Taxonomy Levels 1 & 2)
- Focus exclusively on **Recall & Fundamental Definitions**.
- Questions must test direct factual recall, core terminology, straightforward laws, and standard definitions explicitly stated in the textbook context.
- Avoid complex multi-step numerical calculations, abstract derivations, or indirect application problems.
- MCQs should have obvious distractors with one clear textbook-stated fact."""
        elif diff == "medium":
            return """### COGNITIVE DIFFICULTY LEVEL: MEDIUM (Bloom's Taxonomy Levels 2 & 3)
- Focus on **Conceptual Understanding & Direct Application**.
- Questions must test the student's ability to explain 'why' and 'how', interpret textbook reactions/diagrams, and solve standard textbook numerical problems with given formulas.
- Short questions should require 2-3 step conceptual reasoning.
- MCQs should test conceptual differentiation rather than rote vocabulary memorization."""
        elif diff == "hard":
            return """### COGNITIVE DIFFICULTY LEVEL: HARD (Bloom's Taxonomy Levels 4 & 5)
- Focus on **Analysis, Evaluation & Multi-Step Reasoning**.
- Questions must challenge analytical depth: multi-part derivations, complex numerical calculations requiring multiple formula steps, comparative synthesis between two concepts, or predicting outcomes based on textbook principles.
- MCQs should feature plausible, nuanced distractors testing common misconceptions and edge-cases from the textbook context."""
        else:  # "mixed" / board standard
            return """### COGNITIVE DIFFICULTY LEVEL: MIXED (Official Board Standard Distribution)
- Apply a balanced, standard educational board distribution across the paper:
  - **40% Easy / Knowledge-Based:** Basic recall, textbook definitions, and fundamental units.
  - **40% Medium / Conceptual Application:** Explanations, mechanisms, and standard textbook numericals.
  - **20% Hard / Analytical & Higher-Order Thinking:** Multi-step problem solving, in-depth derivations, and comparative reasoning."""

    @staticmethod
    def _get_requirements(subject: str, chapter_or_topic: str, mcq_count: int, short_count: int, long_count: int, grade: int = 9) -> str:
        return f"""Generate a Class {grade} {subject} test for {chapter_or_topic}.

### TEST REQUIREMENTS:
- **MCQs:** {mcq_count} questions (1 mark each)
- **Short Questions:** {short_count} questions (2 marks each)
- **Long Questions:** {long_count} questions (5 marks each)"""

    @staticmethod
    def _get_teacher_instruction(instruction: str) -> str:
        return f"### ADDITIONAL TEACHER INSTRUCTIONS:\n{instruction.strip()}"

    @staticmethod
    def _get_exercise_focus(exercise: str) -> str:
        return f"### EXERCISE FOCUS:\nFocus questions specifically on content from {exercise.strip()}. Ensure all questions are drawn from this exercise's material."

    @staticmethod
    def _get_context(context: str) -> str:
        return f"<textbook_context>\n{context.strip()}\n</textbook_context>"

    @staticmethod
    def _get_output_instructions() -> str:
        return """### FORMATTING & OUTPUT RULES:
1. Do not use Unicode subscript or superscript characters (such as ₂, ³, etc.) in chemical formulas or math. Instead, you MUST use standard HTML tags. For example, write H<sub>2</sub>O instead of H₂O, and x<sup>2</sup> instead of x².
2. Output MUST strictly adhere to the requested JSON schema."""
