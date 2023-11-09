FROM nvidia/cuda:11.4.3-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
        git \
        python3-pip \
        python3-dev \
        python3-opencv \
        libglib2.0-0


# Copy requirements files
COPY requirements.txt requirements.txt

RUN python3 -m pip install -r requirements.txt

WORKDIR . 

COPY . . 

ENTRYPOINT ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8080", "app:app", "-n"]
