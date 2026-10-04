"""
Official Punjab Textbook Board (PTB) & Federal Board Curriculum Syllabi
for Classes 9, 10, 11, and 12 across all 5 core science subjects.
"""

CURRICULUM_CHAPTERS: dict[int, dict[str, list[str]]] = {
    9: {
        "Chemistry": [
            "Chapter 1: Fundamentals of Chemistry",
            "Chapter 2: Structure of Atoms",
            "Chapter 3: Periodic Table and Periodicity of Properties",
            "Chapter 4: Structure of Molecules",
            "Chapter 5: Physical States of Matter",
            "Chapter 6: Solutions",
            "Chapter 7: Electrochemistry",
            "Chapter 8: Chemical Reactivity"
        ],
        "Physics": [
            "Chapter 1: Physical Quantities & Measurement",
            "Chapter 2: Kinematics",
            "Chapter 3: Dynamics",
            "Chapter 4: Turning Effect of Forces",
            "Chapter 5: Gravitation",
            "Chapter 6: Work and Energy",
            "Chapter 7: Properties of Matter",
            "Chapter 8: Thermal Properties of Matter",
            "Chapter 9: Transfer of Heat"
        ],
        "Mathematics": [
            "Chapter 1: Matrices and Determinants",
            "Chapter 2: Real and Complex Numbers",
            "Chapter 3: Logarithms",
            "Chapter 4: Algebraic Expressions and Algebraic Formulas",
            "Chapter 5: Factorization",
            "Chapter 6: Algebraic Manipulation",
            "Chapter 7: Linear Equations and Inequalities",
            "Chapter 8: Linear Graphs & Their Application",
            "Chapter 9: Introduction to Coordinate Geometry"
        ],
        "Biology": [
            "Chapter 1: Introduction to Biology",
            "Chapter 2: Solving a Biological Problem",
            "Chapter 3: Biodiversity",
            "Chapter 4: Cells and Tissues",
            "Chapter 5: Cell Cycle",
            "Chapter 6: Enzymes",
            "Chapter 7: Bioenergetics",
            "Chapter 8: Nutrition",
            "Chapter 9: Transport"
        ],
        "Computer Science": [
            "Chapter 1: Problem Solving",
            "Chapter 2: Binary System",
            "Chapter 3: Networks",
            "Chapter 4: Data and Privacy",
            "Chapter 5: Designing Website (HTML)"
        ]
    },
    10: {
        "Chemistry": [
            "Chapter 9: Chemical Equilibrium",
            "Chapter 10: Acids, Bases and Salts",
            "Chapter 11: Organic Chemistry",
            "Chapter 12: Hydrocarbons",
            "Chapter 13: Biochemistry",
            "Chapter 14: The Atmosphere",
            "Chapter 15: Water",
            "Chapter 16: Chemical Industries"
        ],
        "Physics": [
            "Chapter 10: Simple Harmonic Motion and Waves",
            "Chapter 11: Sound",
            "Chapter 12: Geometrical Optics",
            "Chapter 13: Electrostatics",
            "Chapter 14: Current Electricity",
            "Chapter 15: Electromagnetism",
            "Chapter 16: Basic Electronics",
            "Chapter 17: Information and Communication Technology",
            "Chapter 18: Atomic and Nuclear Physics"
        ],
        "Mathematics": [
            "Chapter 1: Quadratic Equations",
            "Chapter 2: Theory of Quadratic Equations",
            "Chapter 3: Variations",
            "Chapter 4: Partial Fractions",
            "Chapter 5: Sets and Functions",
            "Chapter 6: Basic Statistics",
            "Chapter 7: Introduction to Trigonometry",
            "Chapter 8: Projection of a Side of a Triangle",
            "Chapter 9: Chords of a Circle",
            "Chapter 10: Tangent to a Circle",
            "Chapter 11: Chords and Arcs",
            "Chapter 12: Angle in a Segment of a Circle",
            "Chapter 13: Practical Geometry - Circles"
        ],
        "Biology": [
            "Chapter 10: Gaseous Exchange",
            "Chapter 11: Homeostasis",
            "Chapter 12: Coordination and Control",
            "Chapter 13: Support and Movement",
            "Chapter 14: Reproduction",
            "Chapter 15: Inheritance",
            "Chapter 16: Man and His Environment",
            "Chapter 17: Biotechnology",
            "Chapter 18: Pharmacology"
        ],
        "Computer Science": [
            "Chapter 1: Introduction to Programming (C Language)",
            "Chapter 2: User Interface (I/O in C)",
            "Chapter 3: Conditional Logic",
            "Chapter 4: Data Structures (Arrays & Loops)",
            "Chapter 5: Functions and Subprograms"
        ]
    },
    11: {
        "Chemistry": [
            "Chapter 1: Basic Concepts",
            "Chapter 2: Experimental Techniques in Chemistry",
            "Chapter 3: Gases",
            "Chapter 4: Liquids and Solids",
            "Chapter 5: Atomic Structure",
            "Chapter 6: Chemical Bonding",
            "Chapter 7: Thermochemistry",
            "Chapter 8: Chemical Equilibrium",
            "Chapter 9: Solutions",
            "Chapter 10: Electrochemistry",
            "Chapter 11: Reaction Kinetics"
        ],
        "Physics": [
            "Chapter 1: Measurements",
            "Chapter 2: Vectors and Equilibrium",
            "Chapter 3: Motion and Force",
            "Chapter 4: Work and Energy",
            "Chapter 5: Circular Motion",
            "Chapter 6: Fluid Dynamics",
            "Chapter 7: Oscillations",
            "Chapter 8: Waves",
            "Chapter 9: Physical Optics",
            "Chapter 10: Optical Instruments",
            "Chapter 11: Heat and Thermodynamics"
        ],
        "Mathematics": [
            "Chapter 1: Number Systems",
            "Chapter 2: Sets, Functions and Groups",
            "Chapter 3: Matrices and Determinants",
            "Chapter 4: Quadratic Equations",
            "Chapter 5: Partial Fractions",
            "Chapter 6: Sequences and Series",
            "Chapter 7: Permutation, Combination and Probability",
            "Chapter 8: Mathematical Induction and Binomial Theorem",
            "Chapter 9: Fundamentals of Trigonometry",
            "Chapter 10: Trigonometric Identities",
            "Chapter 11: Trigonometric Functions and Their Graphs",
            "Chapter 12: Application of Trigonometry",
            "Chapter 13: Inverse Trigonometric Functions",
            "Chapter 14: Solutions of Trigonometric Equations"
        ],
        "Biology": [
            "Chapter 1: Introduction",
            "Chapter 2: Biological Molecules",
            "Chapter 3: Enzymes",
            "Chapter 4: The Cell",
            "Chapter 5: Variety of Life",
            "Chapter 6: Kingdom Prokaryotae (Monera)",
            "Chapter 7: The Kingdom Protista",
            "Chapter 8: Fungi - The Kingdom of Recyclers",
            "Chapter 9: Kingdom Plantae",
            "Chapter 10: Kingdom Animalia",
            "Chapter 11: Bioenergetics",
            "Chapter 12: Nutrition",
            "Chapter 13: Gaseous Exchange",
            "Chapter 14: Transport"
        ],
        "Computer Science": [
            "Chapter 1: Basics of Information Technology",
            "Chapter 2: Information Networks",
            "Chapter 3: Data Communications",
            "Chapter 4: Applications and Uses of Computers",
            "Chapter 5: Computer Architecture",
            "Chapter 6: Security, Copyright and the Law",
            "Chapter 7: Windows Operating System",
            "Chapter 8: Word Processing",
            "Chapter 9: Spreadsheet Software",
            "Chapter 10: Fundamentals of the Internet"
        ]
    },
    12: {
        "Chemistry": [
            "Chapter 1: Periodic Classification of Elements and Periodicity",
            "Chapter 2: s-Block Elements",
            "Chapter 3: Group IIIA and Group IVA Elements",
            "Chapter 4: Group VA and Group VIA Elements",
            "Chapter 5: The Halogens and the Noble Gases",
            "Chapter 6: Transition Elements",
            "Chapter 7: Fundamental Principles of Organic Chemistry",
            "Chapter 8: Aliphatic Hydrocarbons",
            "Chapter 9: Aromatic Hydrocarbons",
            "Chapter 10: Alkyl Halides",
            "Chapter 11: Alcohols, Phenols and Ethers",
            "Chapter 12: Aldehydes and Ketones",
            "Chapter 13: Carboxylic Acids",
            "Chapter 14: Macromolecules",
            "Chapter 15: Common Chemical Industries in Pakistan",
            "Chapter 16: Environmental Chemistry"
        ],
        "Physics": [
            "Chapter 12: Electrostatics",
            "Chapter 13: Current Electricity",
            "Chapter 14: Electromagnetism",
            "Chapter 15: Electromagnetic Induction",
            "Chapter 16: Alternating Current",
            "Chapter 17: Physics of Solids",
            "Chapter 18: Electronics",
            "Chapter 19: Dawn of Modern Physics",
            "Chapter 20: Atomic Spectra",
            "Chapter 21: Nuclear Physics"
        ],
        "Mathematics": [
            "Chapter 1: Functions and Limits",
            "Chapter 2: Differentiation",
            "Chapter 3: Integration",
            "Chapter 4: Introduction to Analytic Geometry",
            "Chapter 5: Linear Inequalities and Linear Programming",
            "Chapter 6: Conic Section",
            "Chapter 7: Vectors"
        ],
        "Biology": [
            "Chapter 15: Homeostasis",
            "Chapter 16: Support and Movements",
            "Chapter 17: Coordination and Control",
            "Chapter 18: Reproduction",
            "Chapter 19: Growth and Development",
            "Chapter 20: Chromosomes and DNA",
            "Chapter 21: Cell Cycle",
            "Chapter 22: Variation and Genetics",
            "Chapter 23: Biotechnology",
            "Chapter 24: Evolution",
            "Chapter 25: Ecosystem",
            "Chapter 26: Some Major Ecosystems",
            "Chapter 27: Man and His Environment"
        ],
        "Computer Science": [
            "Chapter 1: Data Basics",
            "Chapter 2: Basic Concepts and Terminology of Databases",
            "Chapter 3: Database Design Process",
            "Chapter 4: Data Integrity and Normalization",
            "Chapter 5: Introduction to Microsoft Access",
            "Chapter 6: Table and Query",
            "Chapter 7: Microsoft Access Forms and Reports",
            "Chapter 8: Getting Started with C",
            "Chapter 9: Elements of C",
            "Chapter 10: Input / Output",
            "Chapter 11: Decision Constructs",
            "Chapter 12: Loop Constructs",
            "Chapter 13: Functions in C",
            "Chapter 14: File Handling in C"
        ]
    }
}


def get_curriculum_chapters(subject: str, grade: int = 9) -> list[str]:
    """Returns official curriculum chapter list for a given subject and educational grade."""
    grade_data = CURRICULUM_CHAPTERS.get(grade) or CURRICULUM_CHAPTERS[9]
    return grade_data.get(subject) or [
        f"Chapter 1: General {subject}",
        f"Chapter 2: Core Principles",
        f"Chapter 3: Applied Concepts"
    ]
