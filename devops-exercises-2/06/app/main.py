from fastapi import FastAPI
import random

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/random-names")
async def generate_random_name(n: int = 1):
    
    with open("adjectives.txt") as f:
        adjectives = f.readlines()
        adjectives = [adjective.strip("\n") for adjective in adjectives ]
    
    with open("names.txt") as f:
        names = f.readlines()
        names = [name.strip("\n") for name in names ]
        
    random_names = {}
    for i in range(n):
        adjective = random.choice(adjectives)
        name = random.choice(names)
        random_name = f"{adjective.lower()}-{name.lower()}"
        random_names[i] = random_name
    
    return random_names