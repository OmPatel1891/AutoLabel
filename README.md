# AutoLabel: Zero-Shot Image Annotation Pipeline

> Natural language -> labeled dataset, zero manual annotation overhead.

**Stack:** Groq (LLaMA-3.3-70B) · LLaVA 7B (Ollama) · LangGraph · ChromaDB · Gradio · FastAPI · Docker

---

## The Problem

Manually labeling thousands of images is slow, expensive, and error-prone. Most teams spend 30–60% of their ML project time just getting labeled data. Commercial labeling tools (Scale AI, Label Studio) cost money and still require human setup per task.

## What AutoLabel Does

You describe what you want labeled in plain English. AutoLabel handles the rest.

```
"label animals by species, count how many, flag blurry images"
        ↓
Structured labeling schema (via Groq LLaMA-3.3-70B)
        ↓
LLaVA 7B labels every image zero-shot
        ↓
Confidence gate: auto-accept (>0.85) | review queue (0.40–0.85) | reject (<0.40)
        ↓
Export: COCO JSON · YOLO TXT · HuggingFace Dataset
```

---

## System Architecture

```
User natural language
        │
        ▼
┌─────────────────┐
│  Schema Parser  │  ← Groq LLaMA-3.3-70B: NL → structured JSON schema (<200ms)
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│  LangGraph DAG  │────▶│  LLaVA 7B        │  ← Vision model labels each image
│  (6-node state  │     │  (Ollama, local)  │
│   machine)      │     └──────────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Confidence Gate │  auto-accept >0.85 · human review 0.40–0.85 · reject <0.40
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
 Accepted   Flagged → Gradio human-review UI
    │
    ▼
┌─────────────────┐
│    ChromaDB     │  ← semantic search over labeled image embeddings
└────────┬────────┘
         ▼
┌─────────────────┐
│  Export Engine  │  COCO JSON · YOLO TXT · HuggingFace Dataset
└─────────────────┘
         ▼
┌─────────────────┐
│  FastAPI + Docker│  production REST API, fully containerized
└─────────────────┘
```

---

## Quickstart

### Prerequisites

```bash
# 1. Install Ollama and pull LLaVA
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llava:7b
ollama serve

# 2. Clone and install dependencies
git clone https://github.com/OmPatel1891/AutoLabel.git
cd AutoLabel
pip install -r requirements.txt

# 3. Set your Groq API key (free at console.groq.com)
echo "GROQ_API_KEY=gsk_..." > .env
```

### Run the notebook

Open `AutoLabel.ipynb` and run all cells, or jump straight to **Section 13** for the end-to-end demo.

### Docker deployment

```bash
make build
make up           # API: http://localhost:8000/docs | UI: http://localhost:7860
make pull-model   # pulls llava:7b into the container
make label DESC="label animals by species" FOLDER="/app/data/images"
```

### REST API

```bash
curl -X POST http://localhost:8000/label \
  -H 'Content-Type: application/json' \
  -d '{"description": "label by animal species, flag blurry", "image_folder": "/data/images"}'
```

---

## Confidence Gate Logic

| Confidence | Action | Human needed? |
|------------|--------|---------------|
| > 0.85 | Auto-accepted | No |
| 0.40 – 0.85 | Queued for review | Yes (Gradio UI) |
| < 0.40 | Auto-rejected (unlabelable) | No |

Low-confidence images between 0.40 and 0.65 are **retried** with a refined prompt before going to the review queue.

---

## Export Formats

| Format | Use case |
|--------|----------|
| COCO JSON | PyTorch, Detectron2, MMDetection |
| YOLO TXT | YOLOv8, Ultralytics |
| HuggingFace Dataset | `datasets.load_dataset()`, fine-tuning pipelines |

---

## Notebook Structure

| Section | What it covers |
|---------|---------------|
| 0 | Installation & environment setup |
| 1 | Global config, confidence thresholds, API keys |
| 2 | Image loading utilities, demo dataset generator |
| 3 | Schema parser: NL → JSON via Groq |
| 4 | VLM labeling engine (LLaVA via Ollama) |
| 5 | Confidence scoring & routing |
| 6 | LangGraph orchestrator (full pipeline as state machine) |
| 7 | ChromaDB storage & semantic image search |
| 8 | Gradio human-review UI |
| 9 | Export engine (COCO, YOLO, HuggingFace) |
| 10 | FastAPI REST server |
| 11 | Docker setup & Makefile |
| 12 | Evaluation: accuracy, calibration, throughput |
| 13 | End-to-end demo (one cell, full pipeline) |

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| LLM (schema parsing) | Groq API · LLaMA-3.3-70B |
| Vision model | LLaVA 7B via Ollama (local, free) |
| Orchestration | LangGraph (6-node DAG) |
| Vector store | ChromaDB + all-MiniLM-L6-v2 embeddings |
| Review UI | Gradio |
| API | FastAPI + Uvicorn |
| Deployment | Docker + Docker Compose |
| Export | HuggingFace `datasets`, COCO, YOLO |

---

## Author

**Om Mehulbhai Patel** · MS Data Science, University of Michigan  
[GitHub](https://github.com/OmPatel1891) · [LinkedIn](https://linkedin.com/in/om-patel-1891)
