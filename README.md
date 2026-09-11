# Text-to-Speech Chatbot

A full-stack chatbot that streams LLM responses in real time and speaks them back in a cloned voice. Pick your language model (OpenAI GPT-3.5 or Llama 3 70B), pick a voice, and talk to it — or upload a few audio samples to clone a brand new voice on the fly.

![Preview](https://github.com/mohassy/capstone/assets/118586460/0e27b3bf-11ef-45f3-ad6d-e55112ff7241)

## Tech Stack

**Backend**
- FastAPI (Python) — async REST API with streaming responses
- OpenAI Python SDK — `gpt-3.5-turbo` for chat, and the OpenAI-compatible client pointed at DeepInfra's endpoint for `meta-llama/Meta-Llama-3-70B-Instruct`
- ElevenLabs SDK — voice cloning and text-to-speech synthesis (`eleven_monolingual_v1`)
- `python-dotenv` for config, `uvicorn` as the ASGI server

**Frontend**
- React 18 + Vite
- `@chatscope/chat-ui-kit-react` for the chat UI
- React-Bootstrap for layout/navigation
- `react-drag-drop-files` for uploading voice samples

## How It Works

1. The frontend posts the conversation history to either `/chatgpt` or `/llama`, depending on the model selected in the UI.
2. The backend calls the corresponding LLM with `stream=True` and `tee`s the generator into two identical streams:
   - One is returned immediately to the frontend as a `StreamingResponse`, so the chat UI renders tokens as they arrive.
   - The other is handed to a FastAPI `BackgroundTask` that feeds the same token stream straight into ElevenLabs' TTS API, which synthesizes and plays the audio as it's generated — no waiting for the full response before speech starts.
3. Voice cloning works the same way: the frontend uploads a set of audio samples (MP3/M4A/WAV) for a new voice name, the backend saves them under `backend/samples/<voice>`, and calls the ElevenLabs cloning API. Successfully cloned voices are appended to `backend/voices.csv`, which the `/voices` endpoint reads to populate the voice picker in the UI.

## Key Features

- **Dual LLM support** — swap between OpenAI GPT-3.5 and Llama 3 70B (via DeepInfra) from the UI without touching code.
- **Token-level streaming** — chat responses render incrementally instead of waiting for the full completion.
- **Voice cloning** — drag-and-drop audio samples to create a new synthetic voice, no external tooling required.
- **Streaming TTS** — generated text is spoken back using the cloned/selected voice as it streams in, rather than after the response completes.

## API Overview

| Endpoint | Method | Description |
|---|---|---|
| `/chatgpt` | POST | Send `{ messages, voice }`, get back a streamed text response from GPT-3.5 and trigger TTS playback |
| `/llama` | POST | Same as above, routed to Llama 3 70B via DeepInfra |
| `/voices` | GET | List available cloned voice names |
| `/upload/{voice_name}` | POST | Upload audio samples to clone a new voice under that name |

## Getting Started

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create a `.env` file in `backend/` with:

```
GPT_API_KEY=your_openai_api_key
LLAMA_API_KEY=your_deepinfra_api_key
LAB_API_KEY=your_elevenlabs_api_key
```

Run the API:

```bash
uvicorn main:app --reload
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend expects the backend at `http://localhost:8000`.
