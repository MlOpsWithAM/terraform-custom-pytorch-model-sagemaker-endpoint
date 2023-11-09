import os
import ast
import torch
import numpy as np
from typing import List
from fastapi import FastAPI
from pydantic import BaseModel
from torchvision import transforms
from PIL import Image

class Payload(BaseModel):
    input: List[List[float]]
    

def load_model(model_dir):
    model = torch.jit.load(os.path.join(model_dir, 'model.pt'))
    model.to("cuda") if torch.cuda.is_available() else model.to("cpu")
    return model

def predict(preprocessed_image, model):
    preprocessed_image = preprocessed_image.unsqueeze(0)
    if torch.cuda.is_available():
        preprocessed_image = preprocessed_image.to("cuda")
    log_probs = model(preprocessed_image)
    probs = torch.softmax(log_probs, dim=1)
    proba, class_ = torch.max(probs, dim=1)
    output = {'class': class_.detach().cpu().numpy().item(), 
              'proba': proba.detach().cpu().numpy().item()}
    return output

def preprocess(image):
    image = Image.fromarray(np.array(image))
    transform=transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
        ])
    image = transform(image)
    return image

def load_payload(payload: Payload):
    payload = payload.json()
    payload = ast.literal_eval(payload)
    image = payload['input']
    return image

app = FastAPI()
model = load_model(".")


@app.get('/ping')
def pint():
    return "pong"

@app.post('/invocations')
def invoke(payload: Payload):
    image = load_payload(payload)
    image = preprocess(image)
    output = predict(image, model)
    return output