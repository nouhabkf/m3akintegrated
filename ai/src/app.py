from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

_ai_root = Path(__file__).resolve().parent.parent
load_dotenv(_ai_root / ".env")
load_dotenv()

try:
    from src.predict import infer_priority, map_post_to_legacy, predict_action_plan
    from src.accessibility_ai import router as accessibility_router
except ModuleNotFoundError:
    from predict import infer_priority, map_post_to_legacy, predict_action_plan
    from accessibility_ai import router as accessibility_router


class ActionPlanRequest(BaseModel):
    text: str = Field(..., min_length=2, description="User free text")
    contextHint: str | None = Field(default=None, description="post | help | community")
    inputModeHint: str | None = Field(default=None)
    isForAnotherPersonHint: bool | None = Field(default=None)


app = FastAPI(
    title="M3ak IA — Community Action Planner + Accessibilité (Groq)",
    version="0.2.0",
    description=(
        "Plan d'action communauté (ML) et analyse d'accessibilité des lieux (Groq + OSM)."
    ),
)

_cors = os.environ.get("CORS_ORIGINS", "").strip()
if _cors:
    _allow_origins = [o.strip() for o in _cors.split(",") if o.strip()]
    _allow_credentials = True
else:
    _allow_origins = ["*"]
    _allow_credentials = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allow_origins,
    allow_credentials=_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(accessibility_router, prefix="/ai/accessibility")


@app.get("/health")
def health() -> dict:
    groq_configured = bool(os.environ.get("GROQ_API_KEY"))
    return {
        "status": "ok",
        "community_action_planner": "ok",
        "accessibility_ai": "configured" if groq_configured else "missing_groq_key",
        "groq_text_model": os.environ.get("GROQ_TEXT_MODEL", "llama-3.1-8b-instant"),
    }


@app.post("/ai/community/action-plan")
def action_plan(payload: ActionPlanRequest) -> dict:
    try:
        prediction = predict_action_plan(
            text=payload.text,
            context_hint=payload.contextHint,
            input_mode_hint=payload.inputModeHint,
            is_for_another_person_hint=payload.isForAnotherPersonHint,
        )
        if prediction.get("action") == "create_post" and prediction.get("legacyType") is None:
            prediction["legacyType"] = map_post_to_legacy(
                prediction.get("postNature"),
                prediction.get("targetAudience"),
            )
        if prediction.get("predictedPriority") is None:
            prediction["predictedPriority"] = infer_priority(payload.text)
        return prediction
    except FileNotFoundError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc

