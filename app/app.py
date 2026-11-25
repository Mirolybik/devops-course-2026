# KR2: Mkhitarov
import os
import socket

import redis
from flask import Flask, request

app = Flask(__name__)

STUDENT = os.getenv("STUDENT", "Mkhitarov")
PORT = int(os.getenv("PORT", "8001"))

r = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    password=os.getenv("REDIS_PASSWORD") or None,
    decode_responses=True,
)


@app.route("/health")
def health():
    return "ok\n"


@app.route("/")
def index():
    hits = r.incr("hits")
    cid = socket.gethostname()
    return f"KR2 | {STUDENT} | container {cid} | hits: {hits}\n"


@app.route("/whoami")
def whoami():
    return (
        f"scheme: {request.headers.get('X-Forwarded-Proto', request.scheme)}\n"
        f"client: {request.headers.get('X-Real-IP', request.remote_addr)}\n"
        f"host: {request.headers.get('Host', '')}\n"
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
