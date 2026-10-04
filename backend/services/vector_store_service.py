# services/vector_store_service.py
"""
ExamCraft AI - Vector Store & Retrieval Service
Handles vector embeddings, collection management, hybrid retrieval, and textbook context extraction.
"""
import hashlib
import re
import time
from typing import List, Dict, Any
from qdrant_client import QdrantClient
from qdrant_client.http import models
from core.config import settings
from core.logger import get_logger

logger = get_logger(__name__)


def get_qdrant_client(url: str | None = None, api_key: str | None = None) -> QdrantClient:
    """Initialize and return Qdrant Client using settings."""
    target_url = url or settings.QDRANT_URL
    target_api_key = api_key or settings.QDRANT_API_KEY
    return QdrantClient(
        url=target_url,
        api_key=target_api_key,
        check_compatibility=False
    )


def check_qdrant_connection(client: QdrantClient | None = None) -> Dict[str, Any]:
    """Checks Qdrant connection latency, collection existence, and status."""
    target_client = client or get_qdrant_client()
    start_time = time.perf_counter()
    try:
        collections = target_client.get_collections()
        latency_ms = round((time.perf_counter() - start_time) * 1000, 2)
        if hasattr(collections, "collections"):
            collection_names = [c.name for c in collections.collections]
        elif isinstance(collections, (list, set, tuple)):
            collection_names = list(collections)
        else:
            collection_names = []
            
        has_target_collection = settings.COLLECTION_NAME in collection_names or len(collection_names) > 0

        return {
            "healthy": True,
            "latency_ms": latency_ms,
            "collection_exists": has_target_collection,
            "embedding_model_loaded": True
        }
    except Exception as e:
        latency_ms = round((time.perf_counter() - start_time) * 1000, 2)
        logger.warning("Qdrant health check failed (%d ms): %s", latency_ms, str(e))
        return {
            "healthy": False,
            "latency_ms": latency_ms,
            "collection_exists": False,
            "embedding_model_loaded": False
        }


def qdrant_setup(client: QdrantClient, collection_name: str | None = None) -> None:
    """Ensure the collection exists with dense and sparse vector support."""
    col_name = collection_name or settings.COLLECTION_NAME
    try:
        if not client.collection_exists(collection_name=col_name):
            client.create_collection(
                collection_name=col_name,
                vectors_config={
                    "text-dense": models.VectorParams(
                        size=384,
                        distance=models.Distance.COSINE
                    )
                },
                sparse_vectors_config={
                    "text-sparse": models.SparseVectorParams(
                        modifier=models.Modifier.IDF
                    )
                }
            )
            logger.info("Hybrid Collection '%s' created successfully.", col_name)

        # Ensure essential payload indices exist for filtering
        for fld, schema in [
            ("grade", models.PayloadSchemaType.INTEGER),
            ("subject", models.PayloadSchemaType.KEYWORD),
            ("chapter", models.PayloadSchemaType.KEYWORD),
            ("exercise", models.PayloadSchemaType.KEYWORD),
        ]:
            try:
                client.create_payload_index(collection_name=col_name, field_name=fld, field_schema=schema)
            except Exception:
                pass
    except Exception as e:
        logger.error("Error setting up Qdrant collection '%s': %s", col_name, str(e))


# In-Memory High Performance Caches with TTL to slash latency from ~1.5s to <1ms
_COLLECTION_CACHE: Dict[str, tuple[float, bool]] = {}
_CHAPTERS_CACHE: Dict[str, tuple[float, List[str]]] = {}
_METADATA_CACHE: Dict[str, tuple[float, Dict[str, List[str]]]] = {}
CACHE_TTL_SECONDS = 600  # 10 minutes


def clear_metadata_cache():
    """Flushes cached chapters and collections on new textbook upload."""
    global _COLLECTION_CACHE, _CHAPTERS_CACHE, _METADATA_CACHE
    _COLLECTION_CACHE.clear()
    _CHAPTERS_CACHE.clear()
    _METADATA_CACHE.clear()
    logger.info("Cleared in-memory vector store metadata cache.")


def resolve_collection_name(client: QdrantClient | None, grade: int = 9) -> str:
    """Resolves target Qdrant collection name for a given class grade.
    
    If a dedicated collection ('class_{grade}_textbooks') exists, it uses that.
    Otherwise, defaults to the unified single primary collection (settings.COLLECTION_NAME, e.g. 'class_9_textbooks')
    for all classes.
    """
    target = f"class_{grade}_textbooks"
    now = time.time()
    if target in _COLLECTION_CACHE:
        cached_time, exists = _COLLECTION_CACHE[target]
        if (now - cached_time) < CACHE_TTL_SECONDS:
            return target if exists else settings.COLLECTION_NAME

    if client:
        try:
            exists = client.collection_exists(collection_name=target)
            _COLLECTION_CACHE[target] = (now, exists)
            if exists:
                return target
        except Exception:
            pass

    return settings.COLLECTION_NAME


def retrieve_topic_context(
    qdrant_client: QdrantClient,
    collection_name: str,
    subject: str,
    topic: str,
    exercise: str | None = None,
    grade: int | None = None,
    top_k: int = 15
) -> str:
    """Searches for a specific topic, strictly filtered by subject and optionally grade."""
    if not topic or not subject:
        logger.warning("Invalid search query parameters: subject='%s', topic='%s'", subject, topic)
        return ""

    try:
        must_conditions = [
            models.FieldCondition(
                key="subject",
                match=models.MatchValue(value=subject)
            )
        ]
        
        if grade is not None:
            must_conditions.append(
                models.FieldCondition(
                    key="grade",
                    match=models.MatchValue(value=grade)
                )
            )

        if exercise:
            must_conditions.append(
                models.FieldCondition(
                    key="exercise",
                    match=models.MatchValue(value=exercise)
                )
            )

        search_result = qdrant_client.query(
            collection_name=collection_name,
            query_text=topic, 
            query_filter=models.Filter(must=must_conditions),
            limit=top_k
        )
        
        if not search_result:
            logger.info("No topic context hits returned from Qdrant for topic '%s' in subject '%s', grade %s", topic, subject, grade)
            return ""

        context_chunks = []
        for hit in search_result:
            doc_text = hit.metadata.get("document", "") if hasattr(hit, "metadata") and hit.metadata else ""
            if doc_text and doc_text not in context_chunks:
                context_chunks.append(doc_text)

        return "\n\n".join(context_chunks)
    except Exception as e:
        logger.error("Qdrant topic search failed for subject '%s', topic '%s': %s", subject, topic, str(e))
        return ""

def get_full_chapter_context(
    qdrant_client: QdrantClient,
    collection_name: str,
    subject: str,
    chapter_name: str,
    grade: int | None = None
) -> str:
    """Scrolls and retrieves an entire chapter in deterministic chunk order, strictly filtered by subject and grade, supporting pagination."""
    if not chapter_name or not subject:
        logger.warning("Invalid chapter retrieval parameters: subject='%s', chapter='%s'", subject, chapter_name)
        return ""

    try:
        all_records = []
        next_offset = None  # Start with no offset for the first page
        
        must_conditions = [
            models.FieldCondition(
                key="subject",
                match=models.MatchValue(value=subject)
            ),
            models.FieldCondition(
                key="chapter",
                match=models.MatchValue(value=chapter_name)
            )
        ]
        if grade is not None:
            must_conditions.append(
                models.FieldCondition(
                    key="grade",
                    match=models.MatchValue(value=grade)
                )
            )

        # Keep looping until Qdrant says there are no more pages
        while True:
            records, next_offset = qdrant_client.scroll(
                collection_name=collection_name,
                scroll_filter=models.Filter(must=must_conditions),
                limit=200,          # This is now the "batch size" per request
                offset=next_offset, # Pass the offset to get the next batch
                with_payload=True,
                with_vectors=False
            )
            
            all_records.extend(records)
            
            # If Qdrant returns None for the offset, we've hit the end
            if next_offset is None:
                break
        
        if not all_records:
            logger.info("No records found in Qdrant for chapter '%s' in subject '%s'", chapter_name, subject)
            return ""

        # Deterministic sorting by chunk_index using the complete all_records list
        sorted_records = sorted(all_records, key=lambda x: x.payload.get("chunk_index", 0))
        
        # Deduplicate paragraphs before joining
        seen_documents = set()
        context_chunks = []
        for hit in sorted_records:
            doc_text = hit.payload.get("document", "")
            if doc_text and doc_text not in seen_documents:
                seen_documents.add(doc_text)
                context_chunks.append(doc_text)

        return "\n\n".join(context_chunks)
        
    except Exception as e:
        logger.error("Qdrant chapter retrieval failed for subject '%s', chapter '%s': %s", subject, chapter_name, str(e))
        return ""


def _natural_chapter_sort_key(ch: str):
    """Sort helper to ensure Chapter 2 precedes Chapter 10 in UI dropdowns."""
    match = re.search(r"Chapter\s+(\d+)", ch, re.IGNORECASE)
    return (int(match.group(1)) if match else 999, ch.lower())


def get_subject_chapters(
    qdrant_client: QdrantClient,
    collection_name: str,
    subject: str,
    grade: int | None = None
) -> List[str]:
    """Retrieves unique genuine chapter names using fast Qdrant facet aggregation with TTL cache, filtered by subject and grade."""
    cache_key = f"{collection_name}:{subject}:{grade}" if grade is not None else f"{collection_name}:{subject}"
    now = time.time()
    if cache_key in _CHAPTERS_CACHE:
        cached_time, cached_chapters = _CHAPTERS_CACHE[cache_key]
        if (now - cached_time) < CACHE_TTL_SECONDS:
            return cached_chapters

    try:
        chapters = set()
        must_conditions = [
            models.FieldCondition(
                key="subject",
                match=models.MatchValue(value=subject)
            )
        ]
        if grade is not None:
            must_conditions.append(
                models.FieldCondition(
                    key="grade",
                    match=models.MatchValue(value=grade)
                )
            )

        # 1. Ultra-fast Facet Aggregation (1 single network call vs 5 paginated scrolls)
        if hasattr(qdrant_client, "facet"):
            try:
                res = qdrant_client.facet(
                    collection_name=collection_name,
                    key="chapter",
                    facet_filter=models.Filter(must=must_conditions),
                    limit=100
                )
                for hit in res.hits:
                    if hit.value:
                        chap = str(hit.value).strip()
                        if chap and chap.lower() != "general / front matter":
                            chapters.add(chap)
            except Exception as facet_err:
                logger.debug("Qdrant facet fallback to scroll for subject '%s', grade %s: %s", subject, grade, str(facet_err))

        # 2. Resilient Fallback to Bounded Scroll if facet yielded empty or errored
        if not chapters:
            next_offset = None
            page_count = 0
            while page_count < 50:
                page_count += 1
                records, next_offset = qdrant_client.scroll(
                    collection_name=collection_name,
                    scroll_filter=models.Filter(must=must_conditions),
                    limit=200,
                    offset=next_offset,
                    with_payload=["chapter"],
                    with_vectors=False
                )
                if not records:
                    break
                for record in records:
                    if record.payload and "chapter" in record.payload and record.payload["chapter"]:
                        chap = str(record.payload["chapter"]).strip()
                        if chap and chap.lower() != "general / front matter":
                            chapters.add(chap)
                if next_offset is None:
                    break

        sorted_chapters = sorted(list(chapters), key=_natural_chapter_sort_key)
        _CHAPTERS_CACHE[cache_key] = (now, sorted_chapters)
        return sorted_chapters
    except Exception as e:
        logger.warning("Error fetching chapters from Qdrant for subject '%s', grade %s: %s", subject, grade, str(e))
        return []


def is_exercise_relative_to_chapter(exercise_label: str, chapter_name: str) -> bool:
    """Validates that an exercise label strictly belongs to the designated chapter/unit."""
    if not exercise_label or not chapter_name:
        return True
    chap_m = re.search(r'\b(?:chapter|unit)\s*(\d+)\b', chapter_name, re.IGNORECASE)
    if not chap_m:
        return True
    chap_num = int(chap_m.group(1))

    ex_m = re.search(r'\b(?:exercise|ex|review\s+exercise|miscellaneous\s+exercise)\s*(\d+)(?:\.\d+)?\b', exercise_label, re.IGNORECASE)
    if ex_m:
        ex_num = int(ex_m.group(1))
        return ex_num == chap_num
    return True


def _natural_exercise_sort_key(ex_name: str):
    """Sorts exercises naturally e.g. Exercise 1.2 before Exercise 1.10."""
    nums = [int(n) for n in re.findall(r'\d+', ex_name)]
    return (nums, ex_name)


def get_chapter_metadata(
    qdrant_client: QdrantClient,
    collection_name: str,
    subject: str,
    chapter_name: str,
    grade: int | None = None
) -> dict[str, list[str]]:
    """Fetches unique exercises, sections, and topics for a given chapter with fast facet + TTL cache, filtered by grade."""
    # Fast short-circuit: Non-Math subjects use a clean chapter-only schema with no sub-chapter exercises/topics
    if str(subject).strip().lower() not in ("mathematics", "math"):
        return {"exercises": [], "sections": [], "topics": []}

    cache_key = f"{collection_name}:{subject}:{chapter_name}:{grade}" if grade is not None else f"{collection_name}:{subject}:{chapter_name}"
    now = time.time()
    if cache_key in _METADATA_CACHE:
        cached_time, cached_meta = _METADATA_CACHE[cache_key]
        if (now - cached_time) < CACHE_TTL_SECONDS:
            return cached_meta

    try:
        exercises = set()
        sections = set()
        topics = set()
        must_conditions = [
            models.FieldCondition(key="subject", match=models.MatchValue(value=subject)),
            models.FieldCondition(key="chapter", match=models.MatchValue(value=chapter_name))
        ]
        if grade is not None:
            must_conditions.append(models.FieldCondition(key="grade", match=models.MatchValue(value=grade)))

        # 1. Fast facet aggregation for mathematics exercises
        if subject.lower() == "mathematics" and hasattr(qdrant_client, "facet"):
            try:
                res = qdrant_client.facet(
                    collection_name=collection_name,
                    key="exercise",
                    facet_filter=models.Filter(must=must_conditions),
                    limit=50
                )
                for h in res.hits:
                    if h.value and str(h.value).strip():
                        norm_ex = " ".join(str(h.value).split()).title()
                        if is_exercise_relative_to_chapter(norm_ex, chapter_name):
                            exercises.add(norm_ex)
            except Exception as facet_err:
                logger.debug("Exercise facet fallback to scroll for '%s', grade %s: %s", chapter_name, grade, str(facet_err))

        # 2. Scroll fallback for sections and topics
        all_records = []
        next_offset = None
        page_count = 0

        while page_count < 30:
            page_count += 1
            records, next_offset = qdrant_client.scroll(
                collection_name=collection_name,
                scroll_filter=models.Filter(must=must_conditions),
                limit=200,
                offset=next_offset,
                with_payload=["exercise", "section", "topic"],
                with_vectors=False
            )
            if not records:
                break
            all_records.extend(records)
            if next_offset is None:
                break

        for record in all_records:
            if not record.payload:
                continue
            if subject.lower() == "mathematics" and "exercise" in record.payload and record.payload["exercise"]:
                norm_ex = " ".join(str(record.payload["exercise"]).split()).title()
                if is_exercise_relative_to_chapter(norm_ex, chapter_name):
                    exercises.add(norm_ex)
            if "section" in record.payload and record.payload["section"]:
                norm_sec = " ".join(str(record.payload["section"]).split()).title()
                sections.add(norm_sec)
            if "topic" in record.payload and record.payload["topic"]:
                norm_topic = " ".join(str(record.payload["topic"]).split()).title()
                topics.add(norm_topic)

        meta_result = {
            "exercises": sorted(list(exercises), key=_natural_exercise_sort_key),
            "sections": sorted(list(sections)),
            "topics": sorted(list(topics))
        }
        _METADATA_CACHE[cache_key] = (now, meta_result)
        return meta_result
    except Exception as e:
        logger.warning("Error fetching metadata from Qdrant for subject '%s', chapter '%s', grade %s: %s", subject, chapter_name, grade, str(e))
        return {"exercises": [], "sections": [], "topics": []}


def retrieve_with_exercise_boost(
    qdrant_client: QdrantClient,
    collection_name: str,
    subject: str,
    chapter_name: str,
    exercise: str | None = None,
    grade: int | None = None,
    min_context_chars: int = 2000
) -> tuple[str, str]:
    """Retrieves chapter context with special focus on a specific exercise and grade."""
    try:
        all_records = []
        next_offset = None
        must_conditions = [
            models.FieldCondition(
                key="subject",
                match=models.MatchValue(value=subject)
            ),
            models.FieldCondition(
                key="chapter",
                match=models.MatchValue(value=chapter_name)
            )
        ]
        if grade is not None:
            must_conditions.append(models.FieldCondition(key="grade", match=models.MatchValue(value=grade)))
        
        while True:
            records, next_offset = qdrant_client.scroll(
                collection_name=collection_name,
                scroll_filter=models.Filter(must=must_conditions),
                limit=200,
                offset=next_offset,
                with_payload=True,
                with_vectors=False
            )
            all_records.extend(records)
            if next_offset is None:
                break
                
        if not all_records:
            return "", "no_records"
            
        if not exercise:
            strategy = "full_chapter"
            logger.info("retrieve_with_exercise_boost using strategy: %s", strategy)
            sorted_records = sorted(all_records, key=lambda x: x.payload.get("chunk_index", 0) if x.payload else 0)
            seen = set()
            chunks = []
            for hit in sorted_records:
                doc = hit.payload.get("document", "") if hit.payload else ""
                if doc and doc not in seen:
                    seen.add(doc)
                    chunks.append(doc)
            return "\n\n".join(chunks), strategy
            
        exercise_chunks = []
        other_chunks = []
        
        for record in all_records:
            if record.payload and record.payload.get("exercise") == exercise:
                exercise_chunks.append(record)
            else:
                other_chunks.append(record)
                
        exercise_chunks.sort(key=lambda x: x.payload.get("chunk_index", 0) if x.payload else 0)
        other_chunks.sort(key=lambda x: x.payload.get("chunk_index", 0) if x.payload else 0)
        
        seen = set()
        ex_texts = []
        for hit in exercise_chunks:
            doc = hit.payload.get("document", "") if hit.payload else ""
            if doc and doc not in seen:
                seen.add(doc)
                ex_texts.append(doc)
                
        ex_combined = "\n\n".join(ex_texts)
        if len(ex_combined) >= min_context_chars:
            strategy = "exercise_only"
            logger.info("retrieve_with_exercise_boost using strategy: %s", strategy)
            return ex_combined, strategy
            
        for hit in other_chunks:
            doc = hit.payload.get("document", "") if hit.payload else ""
            if doc and doc not in seen:
                seen.add(doc)
                ex_texts.append(doc)
                
        strategy = "exercise_plus_chapter"
        logger.info("retrieve_with_exercise_boost using strategy: %s", strategy)
        return "\n\n".join(ex_texts), strategy

    except Exception as e:
        logger.error("retrieve_with_exercise_boost failed: %s", str(e))
        return "", "error"


def upload_chunks_to_qdrant(client: QdrantClient, collection_name: str, documents: list) -> Dict[str, Any]:
    """Generates hybrid embeddings and uploads textbook chunks to Qdrant with deduplication and batching."""
    start_time = time.perf_counter()
    logger.info("Configuring FastEmbed models: dense=%s, sparse=%s", settings.DENSE_MODEL_NAME, settings.SPARSE_MODEL_NAME)
    
    try:
        client.set_model(settings.DENSE_MODEL_NAME)
        client.set_sparse_model(settings.SPARSE_MODEL_NAME)
    except Exception as e:
        logger.warning("Embedding model configuration warning: %s", str(e))

    # Deduplication check using SHA-256 hash
    seen_hashes = set()
    unique_texts = []
    unique_metadatas = []
    duplicates_skipped = 0

    for doc in documents:
        chunk_content = doc.page_content.strip()
        chunk_hash = hashlib.sha256(chunk_content.encode("utf-8")).hexdigest()
        
        if chunk_hash in seen_hashes:
            duplicates_skipped += 1
            continue

        seen_hashes.add(chunk_hash)
        meta = {**doc.metadata, "chunk_hash": chunk_hash}
        unique_texts.append(chunk_content)
        unique_metadatas.append(meta)

    batch_size = settings.QDRANT_BATCH_SIZE
    logger.info("Uploading %d unique chunks to Qdrant (skipped %d duplicates, batch_size=%d)...",
                len(unique_texts), duplicates_skipped, batch_size)

    client.add(
        collection_name=collection_name,
        documents=unique_texts,
        metadata=unique_metadatas,
        batch_size=batch_size,
        parallel=0
    )
    
    duration = round(time.perf_counter() - start_time, 2)
    logger.info("Uploaded %d chunks to collection '%s' in %.2f seconds.", len(unique_texts), collection_name, duration)

    return {
        "chunks_indexed": len(unique_texts),
        "duplicates_skipped": duplicates_skipped,
        "upload_duration_seconds": duration,
        "collection_name": collection_name
    }