import asyncio
import logging
from contextlib import asynccontextmanager
from io import BytesIO
from typing import AsyncIterator

from fastapi import FastAPI, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import Response
from PIL import Image, UnidentifiedImageError
from rembg import new_session, remove

logger = logging.getLogger(__name__)

MAX_IMAGE_SIZE = 10 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}

rembg_session = None
processing_semaphore = asyncio.Semaphore(1)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    global rembg_session

    logger.info("Loading rembg u2netp model")
    rembg_session = await run_in_threadpool(new_session, "u2netp")
    logger.info("Rembg model loaded")

    yield

    rembg_session = None


app = FastAPI(
    title="Wearly Rembg Service",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health() -> dict[str, str]:
    if rembg_session is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Rembg model is not ready.",
        )

    return {"status": "UP"}


@app.post("/remove-background")
async def remove_background(image: UploadFile) -> Response:
    if image.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Only JPEG, PNG, and WebP images are supported.",
        )

    try:
        image_bytes = await image.read(MAX_IMAGE_SIZE + 1)
    finally:
        await image.close()

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image file is empty.",
        )

    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image file must not exceed 10 MB.",
        )

    try:
        with Image.open(BytesIO(image_bytes)) as input_image:
            input_image.verify()
    except (UnidentifiedImageError, OSError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image file.",
        )

    if rembg_session is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Rembg model is not ready.",
        )

    try:
        async with processing_semaphore:
            output_bytes = await run_in_threadpool(
                remove,
                image_bytes,
                session=rembg_session,
            )
    except Exception as exception:
        logger.exception("Failed to remove image background")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to remove image background.",
        ) from exception

    return Response(
        content=output_bytes,
        media_type="image/png",
    )
