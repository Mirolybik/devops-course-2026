# Практическая работа № 10

Учебное Flask-приложение для проверки CI-конвейера.

CI: Pylint → pytest → Docker build → smoke-test → GHCR.

Публикация образа выполняется только из `main`. В Pull Request выполняются
проверки без push.

- health endpoint: `/health`;
- образ: `ghcr.io/mirolybik/devops-course-2026`;
- основной workflow: `.github/workflows/ci.yml`.

## Локальная проверка

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r app/requirements.txt -r requirements-dev.txt
python -m pylint app --score=no
python -m pytest -q
docker build -t devops-ci-app:local .
docker run --rm -p 127.0.0.1:5000:5000 devops-ci-app:local
curl --fail http://127.0.0.1:5000/health
```
