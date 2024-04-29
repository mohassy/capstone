import os
import base64
from elevenlabs.client import ElevenLabs
from dotenv import load_dotenv


async def clone_voice(voice_name, file_names):
    load_dotenv()
    KEY = os.getenv("LAB_API_KEY")
    client = ElevenLabs(
        api_key=KEY,
    )
    file_paths = [f"./samples/{voice_name.lower()}/{file_name}" for file_name in file_names]
    voice = client.clone(
        name=voice_name,
        description="",  # Optional
        files=file_paths,  # Pass the file data as bytes
    )
    if(voice is not None):
        print(f"successfully created voice: {voice}")
        return True
    return False



if __name__ == "__main__":
    # Load environment variables from .env file
    load_dotenv()
    KEY = os.getenv("LAB_API_KEY")

    client = ElevenLabs(
        api_key=KEY,  # Defaults to ELEVEN_API_KEY
    )
    name = input("Enter name:")
    description = input("Enter description:")
    # folder path
    dir_path = f"./samples/{name.lower()}"

    # list to store files
    res = []

    # Iterate directory
    for path in os.listdir(dir_path):
        # check if current path is a file
        if os.path.isfile(os.path.join(dir_path, path)):
            res.append(dir_path + '/' + path)

    voice = client.clone(
        name=name,
        description=description,  # Optional
        files=res,
    )
    print(f"successfully created voice: {voice}")
