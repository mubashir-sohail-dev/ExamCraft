from services.vector_store_service import get_qdrant_client, get_subject_chapters, resolve_collection_name
from core.config import settings

client = get_qdrant_client()

subjects = ["Mathematics", "Chemistry", "Physics", "Biology", "Computer Science"]
grades = [9, 10, 11, 12]

print(f"Primary Collection: {settings.COLLECTION_NAME}")

for grade in grades:
    col = resolve_collection_name(client, grade)
    print(f"\n================ GRADE {grade} (Collection: {col}) ================")
    for sub in subjects:
        chapters = get_subject_chapters(client, col, sub, grade=grade)
        print(f"  [{sub}] ({len(chapters)} chapters):")
        for ch in chapters[:5]:
            print(f"    - {ch}")
        if len(chapters) > 5:
            print(f"    ... and {len(chapters) - 5} more")
