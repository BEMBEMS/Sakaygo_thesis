import numpy as np
from fastapi import FastAPI

SERVICE_NAME = "tricycle-matching-engine"

app = FastAPI(title=SERVICE_NAME, version="0.1.0")


@app.get("/health")
async def health() -> dict[str, object]:
    return {
        "service": SERVICE_NAME,
        "status": "ok",
        "algorithm": "hungarian",
        "numpy": np.__version__,
    }
