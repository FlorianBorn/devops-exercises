FROM ubuntu:20.04

RUN apt-get -y update && \
    apt-get -y install python3-pip && \
    pip3 install "fastapi[all]"

COPY app/ /app/

WORKDIR /app

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1" ]
