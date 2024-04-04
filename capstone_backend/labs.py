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

class Lab:
    def __init__(self):
        self.voice = "Hassan"

    def set_voice(self, voice):
        self.voice = voice

    async def generate_audio(self, text_stream):
        audio_stream = client.generate(
            text=text_stream,
            voice=self.voice,
            model="eleven_monolingual_v1",
            # model="eleven_multilingual_v2",
            stream=True,
        )
        # Stream the audio
        try:
            stream(audio_stream)
        except KeyError as e:
            print(f"KeyError: {e}")
