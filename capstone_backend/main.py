from itertools import tee

from fastapi import FastAPI, BackgroundTasks
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from chatgpt import chatgpt_process_input
from llama2 import llama2_process_input
from labs import Lab
from pydantic import BaseModel

app = FastAPI()
lab = Lab()

# Allow all origins for CORS (you can restrict it to specific origins if needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


class Message(BaseModel):
    message: str


class Voice(BaseModel):
    voice: str


@app.post("/message_chatgpt")
async def chatgpt(item: Message, background_tasks: BackgroundTasks):
    # Process the input message
    stream1, stream2 = tee(chatgpt_process_input(item.message))
    # Queue the generate_audio function as a background task
    background_tasks.add_task(lab.generate_audio, stream1)
    return StreamingResponse(stream2, media_type="text/plain")


@app.post("/message_llama2")
async def llama2(item: Message, background_tasks: BackgroundTasks):
    # Process the input message
    stream1, stream2 = tee(llama2_process_input(item.message))
    # Queue the generate_audio function as a background task
    background_tasks.add_task(lab.generate_audio, stream1)
    return StreamingResponse(stream2, media_type="text/plain")


@app.put("/voice")
async def voice(v: Voice):
    print(v.voice)
    lab.set_voice(v.voice)
