from elevenlabs import stream
import os
from elevenlabs.client import ElevenLabs
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
KEY = os.getenv("LAB_API_KEY")

client = ElevenLabs(
    api_key=KEY,  # Defaults to ELEVEN_API_KEY
)


def generate_audio(text_stream, voice):
    print("Generating audio...")
    audio_stream = client.generate(
        text=text_stream,
        voice=voice,
        model="eleven_monolingual_v1",
        stream=True,
    )
    # Stream the audio
    try:
        stream(audio_stream)
    except KeyError as e:
        print(f"KeyError: {e}")
