import time
from fastapi import APIRouter, Depends, Response, status
from core.exceptions import PDFProcessingError, InvalidRequestError
from core.logger import get_logger
from core.security import verify_api_key
from schemas.request_schemas import PDFRenderRequest
from services.pdf_generator import generate_test_pdf

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/tests",
    tags=["PDF"],
    dependencies=[Depends(verify_api_key)]
)


@router.post(
    "/render-pdf",
    response_class=Response,
    status_code=status.HTTP_200_OK,
    summary="Render PDF Examination Paper",
    description=(
        "Renders approved Class9TestSchema JSON data into a formatted, publication-ready PDF paper "
        "and streams binary PDF data back to the client for download."
    ),
    responses={
        200: {
            "content": {"application/pdf": {}},
            "description": "Binary PDF file download."
        }
    }
)
def render_pdf_endpoint(payload: PDFRenderRequest):
    """Converts approved test JSON into a PDF binary stream."""
    start_time = time.perf_counter()
    logger.info("PDF render request received for subject='%s', title='%s'",
                payload.test_data.subject, payload.test_data.test_title)

    # Validate that at least one section has questions
    total_questions = len(payload.test_data.mcqs) + len(payload.test_data.short_questions) + len(payload.test_data.long_questions)
    if total_questions == 0:
        logger.warning("Rejected PDF render request: Test contains 0 questions across all sections.")
        raise InvalidRequestError(detail="Test paper cannot be rendered because it contains zero questions.")

    pdf_buffer = None
    try:
        pdf_buffer = generate_test_pdf(
            test_data=payload.test_data,
            include_answer_key=payload.include_answer_key
        )

        pdf_bytes = pdf_buffer.getvalue()
        render_duration = round(time.perf_counter() - start_time, 2)

        import re
        safe_subject = re.sub(r"[^a-zA-Z0-9_\-]", "", payload.test_data.subject.replace(" ", "_")) or "Assessment"
        grade_val = getattr(payload.test_data, "grade", 9) or 9
        filename = f"{safe_subject}_Grade{grade_val}_Test.pdf"

        headers = {
            "Content-Disposition": f'attachment; filename="{filename}"'
        }

        logger.info("PDF rendered successfully (%d bytes) in %.2fs for Grade %d", len(pdf_bytes), render_duration, grade_val)
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers=headers
        )

    except InvalidRequestError:
        raise
    except Exception as e:
        logger.exception("Failed to render PDF: %s", str(e))
        raise PDFProcessingError(detail=f"Failed to render PDF examination paper: {str(e)}", status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    finally:
        if pdf_buffer and hasattr(pdf_buffer, "close"):
            try:
                pdf_buffer.close()
            except Exception:
                pass
