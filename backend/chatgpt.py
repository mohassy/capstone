import os

from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
KEY = os.getenv("GPT_API_KEY")
messages = [{"role": "system", "content": "You are a helpful AI assistant"}]


def chatgpt_process_input(messages):
    client = OpenAI(
        api_key=KEY,
    )
    stream = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=messages,
        stream=True,
    )
    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content