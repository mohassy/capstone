from itertools import tee
import os
import csv
from fastapi import FastAPI, BackgroundTasks, UploadFile
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from chatgpt import chatgpt_process_input
from llama import llama_process_input
from labs import generate_audio
from pydantic import BaseModel
from typing import List
from clone import clone_voice
app = FastAPI()

# Allow all origins for CORS (you can restrict it to specific origins if needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

class Message(BaseModel):
    role: str
    content: str

class File(BaseModel):
    name: str
    data: bytes
class Voice(BaseModel):
    files: List[File]
    voice: str

class Request(BaseModel):
    messages: List[Message]
    voice: str

# Define the file path
voices_path = 'voices.csv'

# Function to read the CSV file and return its content as a list
def read_voices():
    voices = []
    with open(voices_path, 'r') as file:
        reader = csv.reader(file)
        next(reader)  # Skip the header row
        for row in reader:
            voices.append(row[0])
    return voices

# function that opens CSV file and writes the voice name to it
def write_voice(voice_name):
    with open(voices_path, 'a', newline='\n') as file:
        writer = csv.writer(file)
        writer.writerow([voice_name])

@app.get("/voices")
async def get_voices():
    return read_voices()

@app.post("/chatgpt")
async def chatgpt(request: Request, background_tasks: BackgroundTasks):
    # Process the input message
    stream1, stream2 = tee(chatgpt_process_input(request.messages))
    # Queue the generate_audio function as a background task
    background_tasks.add_task(generate_audio, stream1, request.voice)
    return StreamingResponse(stream2, media_type="text/plain")


@app.post("/llama")
async def llama(request: Request, background_tasks: BackgroundTasks):
    # Process the input message
    stream1, stream2 = tee(llama_process_input(request.messages))
    # Queue the generate_audio function as a background task
    background_tasks.add_task(generate_audio, stream1, request.voice)
    return StreamingResponse(stream2, media_type="text/plain")

@app.post("/upload/{voice_name}")
async def create_upload_files(files: list[UploadFile], voice_name):
    directory_path = f"./samples/{voice_name.lower()}"
    # create directory if it doesn't exist
    if not os.path.exists(directory_path):
        # Create the directory
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created successfully.")
    else:
        print(f"Directory '{directory_path}' already exists.")
    for file in files:
        file_path = f"./samples/{voice_name.lower()}/{file.filename}"
        file_content = await file.read()
        with open(file_path, "wb") as file:
            # Write the content to the file
            file.write(file_content)
    file_names = [file.filename for file in files]
    success = await clone_voice(voice_name, file_names)
    if success:
        write_voice(voice_name)
    return {"filenames": file_names, "voice": voice_name}