# Django Redis Postgres App

A Django REST Framework backend application with PostgreSQL as the database and Redis for caching, fully dockerized and tested with GitHub Actions CI.

## Tech Stack

- **Django** + **Django REST Framework** — backend and API
- **PostgreSQL 16** — relational database
- **Redis** — caching layer
- **Docker** + **Docker Compose** — containerization
- **GitHub Actions** — CI/CD pipeline
- **GitHub Container Registry (GHCR)** — container image registry

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/books/` | Create a new book |
| `GET` | `/api/books/` | Retrieve all books |
| `GET` | `/api/redis-test/` | Check Redis connection status |

## Project Structure
```
├── books/
│   ├── models.py        # Book model
│   ├── serializers.py   # DRF serializers
│   ├── views.py         # API views
│   └── urls.py          # App URLs
├── .github/
│   └── workflows/
│       └── ci.yml       # GitHub Actions workflow
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── manage.py
```

## Docker Setup

The application runs in 3 containers connected via a shared `app-network`:

- **django-app** — Django application server
- **db** — PostgreSQL 16 database
- **cache** — Redis cache

### Running the project

1. Clone the repository:
```bash
git clone git@github.com:username/your-repo.git
cd your-repo
```

2. Create your `.env` file:
```bash
cp .env.example .env
```

3. Update `.env` with your values:
```bash
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=db
DB_PORT=5432
REDIS_URL=redis://cache:6379/1
SECRET_KEY=your_secret_key
DEBUG=True
```

4. Build and start the containers:
```bash
docker compose up --build -d
```

The app will be available at `http://localhost:8000`

### Stopping the project
```bash
docker compose down
```

## Container Registry

The Docker image is published to GitHub Container Registry (GHCR) and is updated on every push to `main`.

### Pull the image
```bash
docker pull ghcr.io/gabrielmcryu/django-app:latest
```

### Run directly from the registry
```bash
docker pull ghcr.io/gabrielmcryu/django-app:latest
```

Images are tagged with both `latest` and the commit SHA for traceability:
- `ghcr.io/gabrielmcryu/django-app:latest` — most recent build
- `ghcr.io/gabrielmcryu/django-app:<commit-sha>` — specific commit build

## CI/CD

The GitHub Actions workflow runs on every push to `main` and:

**Test job:**
1. Creates the `.env` file from GitHub Secrets
2. Builds and starts all Docker containers
3. Waits for services to be ready
4. Tests all 3 endpoints
5. Tears down the containers

**Publish job** (runs only if tests pass):
1. Logs in to GitHub Container Registry
2. Builds the Docker image
3. Pushes the image tagged with `latest` and the commit SHA to GHCR