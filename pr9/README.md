# Практическая работа № 9

Статический деплой и первый CI: Pylint, MkDocs, GitHub Actions и GitHub Pages.

- исходники документации: `docs/`;
- конфигурация MkDocs: `mkdocs.yml`;
- CI: `.github/workflows/quality.yml`;
- публикация: `.github/workflows/pages.yml`.

Каталог `site/` является результатом сборки и не хранится в Git.

## Локальная проверка

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements-dev.txt
python -m pylint src/status.py --score=no
mkdocs build --strict --site-dir /tmp/docs-site
```
