FROM python:3.12-slim
RUN useradd --system --no-create-home app
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV PORT=8001
USER app
EXPOSE 8001
CMD ["python", "app.py"]
