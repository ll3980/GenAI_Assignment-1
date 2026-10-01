FROM python:3.12-slim-bookworm

# Install uv from its official container image.
COPY --from=ghcr.io/astral-sh/uv:0.12.18 /uv /uvx /bin/

WORKDIR /code
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=never
ENV PYTHONUNBUFFERED=1
ENV PATH="/code/.venv/bin:$PATH"

COPY pyproject.toml uv.lock /code/
RUN uv sync --locked --no-dev --no-cache --python /usr/local/bin/python

COPY app /code/app
COPY scripts /code/scripts

# Fail the build if the actual pretrained model is missing or unusable.
RUN python -c "from app.embedding_model import calculate_embedding; r = calculate_embedding('apple'); assert r['model_version'] == '3.8.0'; assert r['dimensions'] == len(r['embedding']) == 300; assert r['has_vector']"

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:80/', timeout=3).read()"]

CMD ["/code/.venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
