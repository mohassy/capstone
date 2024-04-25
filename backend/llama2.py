from openai import OpenAI
from dotenv import load_dotenv
import os
# Load environment variables from .env file
load_dotenv()
KEY = os.getenv("LLAMA_API_KEY")
messages = []


def llama2_process_input(text_input):
    client = OpenAI(
        api_key=KEY,
        base_url="https://api.deepinfra.com/v1/openai")
    messages.append({"role": "user", "content": text_input})
    model_id = "meta-llama/Meta-Llama-3-70B-Instruct"
    stream = client.chat.completions.create(
        model=model_id,
        messages=messages,
        stream=True,
        max_tokens=100
    )
    # return the chat completion in stream format
    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content
