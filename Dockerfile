FROM python:3.12-alpine

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen

COPY . .

EXPOSE 8000

CMD ["uv", "run", "manage.py", "runserver", "0.0.0.0:8000"]