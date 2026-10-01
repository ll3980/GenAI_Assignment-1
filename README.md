# Assignment 1: Text Generation and Word Embedding API

**Student: Liuyang Li**  
**Course: Applied Generative AI, Fall 2026**

This project adds the spaCy word embedding operation from Module 2 to the FastAPI text generation application from Module 3. The original `POST /generate` endpoint remains available. The new `POST /embedding` endpoint accepts one query word and returns its complete pretrained vector; `GET /embedding?word=apple` supports the same operation through a query parameter. The project includes a Docker deployment, locked dependencies, API tests, and a GitHub Actions workflow that builds and queries the container.

## Docker deployment

On Windows or macOS, install and start Docker Desktop with Linux containers. On Linux, use Docker Engine with Docker Compose v2. Run all commands from the project directory containing `Dockerfile`, `compose.yaml`, and `pyproject.toml`.

```bash
docker compose up --build --detach --wait --wait-timeout 180
```

The first build needs an Internet connection to install dependencies and the official `en_core_web_lg` 3.8.0 model. The model wheel is approximately 401 MB. The model is installed inside the image, and the build checks that it can return a 300-dimensional vector. API inference uses the CPU and requires no GPU, API key, or paid service. The installed model is reused across requests.

The container listens on port 80, mapped to port 8000 on the host. Open <http://127.0.0.1:8000/docs> to query the API. The first embedding request loads the model into memory and may take longer than later requests.

Verify the running container using its installed Python interpreter:

```bash
docker compose exec -T api python scripts/check_api.py --base-url http://127.0.0.1:80
```

A successful verification ends with `All API checks passed.` The script checks the running HTTP server, Swagger UI, endpoint schema, the complete vector, GET/POST agreement, input errors, and the original text generator. To check the host port instead, run `python scripts/check_api.py --base-url http://127.0.0.1:8000` on a host with Python installed.

View logs or stop the deployment:

```bash
docker compose logs --tail 50 api
docker compose down
```

If port 8000 is occupied, stop the existing development server before starting this deployment. A plain Docker alternative is also supported:

```bash
docker build -t sps-genai-assignment1 .
docker run --rm -p 8000:80 sps-genai-assignment1
```

## API requests and responses

| Method | Endpoint | Input | Result |
| --- | --- | --- | --- |
| GET | `/` | None | Server status: `{"Hello":"World"}` |
| POST | `/embedding` | JSON: `{"word":"apple"}` | Complete spaCy word vector and model metadata |
| GET | `/embedding` | Query: `?word=apple` | Same embedding response |
| POST | `/generate` | JSON: `{"start_word":"the","length":20}` | `generated_text` from the classroom bigram model |

### Word embedding

In Swagger UI, expand **POST /embedding**, select **Try it out**, enter this JSON, and select **Execute**:

```json
{"word": "apple"}
```

For a direct browser query, open <http://127.0.0.1:8000/embedding?word=apple>. Both methods return HTTP 200 and the following fields:

| Field | Meaning |
| --- | --- |
| `word` | Query word with surrounding whitespace removed |
| `model` | `en_core_web_lg`, as used in Module 2 |
| `model_version` | `3.8.0`, the pinned pretrained model version |
| `dimensions` | `300` |
| `has_vector` | `true` for a successful result |
| `embedding` | JSON array containing all 300 numeric vector values |

The complete response captured from the real API is in `examples/apple_embedding.json`.

The implementation uses the classroom operation `nlp(word).vector`; `.tolist()` serializes the NumPy vector as JSON. It loads the model once per server process and reuses it. Parsing and tagging components are excluded because this endpoint needs static word vectors. The unit tests compare its full output against the full classroom spaCy pipeline.

Input is one alphabetic word that spaCy tokenizes as one token. Surrounding whitespace is removed and case is preserved. Blank input, multiple words, numbers, punctuation, or words longer than 100 characters return HTTP 422. A word without a pretrained vector returns HTTP 404. An unavailable model returns HTTP 503 with installation instructions.

### Text generation

Use **POST /generate** with:

```json
{"start_word": "the", "length": 20}
```

The generator samples each next word from observed bigram probabilities in the Module 3 sample corpus. `length` includes the starting word and must be an integer from 1 to 200. The generator stops early when a word has no observed successor. Results may differ across calls because the next word is sampled randomly. An unknown starting word returns HTTP 404.

Transitions are counted within each corpus text. For every word with observed successors, their probabilities sum to one.

## Run locally with uv

The project uses Python 3.12. From the project directory:

```bash
uv sync --locked
uv run uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The first sync installs the vector model automatically. Keep the server terminal running and open <http://127.0.0.1:8000/docs>. Stop the server with Ctrl+C. From a second terminal, run the tests and live HTTP checks:

```bash
uv run pytest -q
uv run python scripts/check_api.py --base-url http://127.0.0.1:8000
```

`requirements.txt` provides the runtime dependencies for a pip-based installation if uv is unavailable.

## Project organization

| Path | Responsibility |
| --- | --- |
| `app/main.py` | FastAPI endpoints, request/response schemas, and HTTP errors |
| `app/embedding_model.py` | Cached spaCy model and complete word vector calculation |
| `app/bigram_model.py` | Classroom bigram probabilities and text generation |
| `pyproject.toml`, `uv.lock` | Dependency declarations and locked package versions |
| `Dockerfile`, `compose.yaml` | Image build, model installation, server startup, and port mapping |
| `scripts/check_api.py` | Live HTTP checks requiring only Python's standard library |
| `tests/test_api.py` | Tests against real pretrained vectors and bigram behavior |
| `examples/` | Responses captured from the running API |
| `.github/workflows/docker-api.yml` | Automated Docker build and HTTP checks on GitHub |
| `VALIDATION.md` | Recorded verification results and remaining deployment checks |

## Rubric coverage

| Criterion | Submitted material or verification |
| --- | --- |
| New code committed to GitHub (10 points) | Commit this project to the student's GitHub repository and submit its URL |
| Docker deployment on the instructor's machine (20 points) | Dockerfile, Compose configuration, model installed in the image, and documented build/start commands |
| Queryable algorithm or model (20 points) | GET/POST word embedding endpoints, the original generator, Swagger UI, and live API check script |
| Organization and functionality (20 points) | Separate API/model modules, schemas, error handling, locked dependencies, tests, and documentation |
| Correct probability calculations (30 points) | Separate probability solutions PDF containing all six questions and derivations |

## GitHub and CourseWorks submission

Commit the contents of this project directory to GitHub, including `app/`, `scripts/`, `tests/`, `examples/`, `.github/`, the Docker files, dependency files, and documentation. The instructor should be able to open the source files directly and run the Docker commands from the repository root. Ensure that the instructor can access the repository.

The GitHub Actions workflow runs after a push when Actions is enabled for the repository. Review **Actions > Docker API checks** and confirm the workflow succeeds. A workflow file by itself is not evidence of a successful Docker run; the workflow run must pass.

Submit the probability solutions PDF through CourseWorks and provide the actual GitHub repository URL in the submission field or comment required by the course. The code's GitHub commit and the CourseWorks submission must be completed in the student's accounts.

## References

- Module 2 Practical 3: Word Embeddings, supplied course material.
- Module 2 Practical 2: Word Sampling, supplied course material.
- Module 3 Activity: First Docker/FastAPI Project Setup and Simple Text Generator, supplied course material.
- [spaCy vectors and similarity](https://spacy.io/usage/linguistic-features#vectors-similarity).
- [FastAPI request bodies](https://fastapi.tiangolo.com/tutorial/body/).
- [uv in Docker](https://docs.astral.sh/uv/guides/integration/docker/).
- [Docker Compose startup](https://docs.docker.com/reference/cli/docker/compose/up/).
