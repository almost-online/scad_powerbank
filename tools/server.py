#!/usr/bin/env python3
"""FastAPI Backend Server for PowerBank Board Sketcher."""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

import uvicorn
from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

ROOT_DIR = Path(__file__).resolve().parent.parent
BOARDS_DIR = ROOT_DIR / "boards"
IMAGES_DIR = BOARDS_DIR / "images"
TOOLS_DIR = ROOT_DIR / "tools"

IMAGES_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="PowerBank Board Sketcher API",
    description="REST backend for managing board presets, images, and generating OpenSCAD modules",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def run_scad_generator():
    """Execute tools/generate_board_presets.py and return output & status."""
    gen_script = TOOLS_DIR / "generate_board_presets.py"
    try:
        res = subprocess.run(
            [sys.executable, str(gen_script)],
            capture_output=True,
            text=True,
            cwd=str(ROOT_DIR),
            check=True,
        )
        return {
            "success": True,
            "stdout": res.stdout.strip(),
            "stderr": res.stderr.strip(),
        }
    except subprocess.CalledProcessError as err:
        return {
            "success": False,
            "stdout": err.stdout.strip() if err.stdout else "",
            "stderr": err.stderr.strip() if err.stderr else str(err),
            "exit_code": err.returncode,
        }
    except Exception as exc:
        return {
            "success": False,
            "stdout": "",
            "stderr": str(exc),
        }


def find_board_image_path(board_id: str) -> Optional[Path]:
    """Find image associated with board ID in IMAGES_DIR."""
    for ext in [".png", ".jpg", ".jpeg", ".webp"]:
        path = IMAGES_DIR / f"{board_id}{ext}"
        if path.exists() and path.is_file():
            return path
    return None


@app.get("/", response_class=HTMLResponse)
async def index():
    """Serve the main board sketcher web UI."""
    sketcher_html = TOOLS_DIR / "board_sketcher.html"
    if not sketcher_html.exists():
        raise HTTPException(status_code=404, detail="board_sketcher.html not found")
    return HTMLResponse(content=sketcher_html.read_text(encoding="utf-8"))


@app.get("/api/boards")
async def list_boards():
    """List all available board presets with metadata."""
    boards = []
    if not BOARDS_DIR.exists():
        return boards

    for file_path in sorted(BOARDS_DIR.glob("*.json")):
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            board_id = data.get("id", file_path.stem)
            image_path = find_board_image_path(board_id)
            board_dim = data.get("board", {})
            boards.append(
                {
                    "id": board_id,
                    "name": data.get("name", board_id),
                    "units": data.get("units", "mm"),
                    "width": board_dim.get("width", 0),
                    "length": board_dim.get("length", 0),
                    "height": board_dim.get("height", 0),
                    "radius": board_dim.get("radius", 0),
                    "ports_count": len(data.get("ports", [])),
                    "displays_count": len(data.get("displays", [])),
                    "buttons_count": len(data.get("buttons", [])),
                    "has_image": image_path is not None,
                    "image_url": f"/api/boards/{board_id}/image" if image_path else None,
                }
            )
        except Exception as e:
            continue
    return boards


@app.get("/api/boards/{board_id}")
async def get_board(board_id: str):
    """Retrieve full board specification JSON."""
    board_path = BOARDS_DIR / f"{board_id}.json"
    if not board_path.exists():
        raise HTTPException(status_code=404, detail=f"Board '{board_id}' not found")
    try:
        with open(board_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        image_path = find_board_image_path(board_id)
        data["has_image"] = image_path is not None
        data["image_url"] = f"/api/boards/{board_id}/image" if image_path else None
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed reading board: {e}")


@app.get("/api/boards/{board_id}/image")
async def get_board_image(board_id: str):
    """Serve the reference board photo."""
    image_path = find_board_image_path(board_id)
    if not image_path:
        raise HTTPException(status_code=404, detail=f"Image for board '{board_id}' not found")
    media_type = "image/png"
    if image_path.suffix.lower() in [".jpg", ".jpeg"]:
        media_type = "image/jpeg"
    elif image_path.suffix.lower() == ".webp":
        media_type = "image/webp"
    return FileResponse(image_path, media_type=media_type)


@app.post("/api/boards/{board_id}")
async def save_board(
    board_id: str,
    request: Request,
    image: Optional[UploadFile] = File(None),
    board_data: Optional[str] = Form(None),
):
    """Save or update board specification and optional reference photo, then regenerate SCAD."""
    payload = None
    content_type = request.headers.get("content-type", "")

    if "application/json" in content_type:
        try:
            payload = await request.json()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid JSON payload: {e}")
    else:
        # Form / Multipart
        if board_data:
            try:
                payload = json.loads(board_data)
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Invalid JSON in 'board_data': {e}")
        else:
            try:
                # Try reading body as json if form fields were not passed
                body_bytes = await request.body()
                if body_bytes:
                    payload = json.loads(body_bytes.decode("utf-8"))
            except Exception:
                pass

    if not payload or not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="Missing or invalid board JSON specification")

    # Ensure ID matches
    payload["id"] = board_id

    board_path = BOARDS_DIR / f"{board_id}.json"
    with open(board_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
        f.write("\n")

    # Save image if provided
    if image and image.filename:
        # Determine extension
        orig_ext = Path(image.filename).suffix.lower()
        if orig_ext not in [".png", ".jpg", ".jpeg", ".webp"]:
            orig_ext = ".png"
        saved_img_path = IMAGES_DIR / f"{board_id}{orig_ext}"
        content = await image.read()
        if len(content) > 0:
            with open(saved_img_path, "wb") as img_file:
                img_file.write(content)

    # Re-run SCAD generator
    gen_result = run_scad_generator()

    return {
        "status": "ok" if gen_result["success"] else "warning",
        "board_id": board_id,
        "message": "Board saved and OpenSCAD presets updated"
        if gen_result["success"]
        else "Board saved, but OpenSCAD generation had errors",
        "generator": gen_result,
    }


@app.post("/api/generate")
async def trigger_generation():
    """Manually trigger OpenSCAD generator."""
    gen_result = run_scad_generator()
    return {
        "status": "ok" if gen_result["success"] else "error",
        "generator": gen_result,
    }


if __name__ == "__main__":
    uvicorn.run("tools.server:app", host="0.0.0.0", port=8000, reload=True)
