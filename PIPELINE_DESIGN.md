# PIPELINE_DESIGN.md

## Plateforme choisie : GitHub Actions

### Comparaison des plateformes CI/CD

| Critère | GitHub Actions | GitLab CI | CircleCI |
|---|---|---|---|
| Prix (repos publics) | Gratuit (2000 min/mois) | Gratuit (400 min/mois) | Gratuit (6000 min/mois) |
| Syntaxe | YAML, natif GitHub | YAML | YAML |
| Écosystème | Marketplace d'actions très riche | Intégré à GitLab | Orbs (plugins) |
| Courbe d'apprentissage | Faible (intégré à GitHub) | Moyenne | Moyenne |

**Choix : GitHub Actions** — le repo est sur GitHub, l'intégration est native, le `GITHUB_TOKEN` donne accès à GHCR sans configuration supplémentaire.

---

## Registry Docker choisi : GHCR (GitHub Container Registry)

| Registry | Avantage |
|---|---|
| GHCR | Intégré à GitHub, auth via `GITHUB_TOKEN`, gratuit pour repos publics |
| Docker Hub | Universel mais rate-limiting sur le tier gratuit |
| Amazon ECR / GCP Artifact Registry | Adapté au cloud, payant, complexe à configurer |

**Choix : GHCR** — même écosystème que le repo, zéro configuration de secrets supplémentaires.

---

## Architecture de la pipeline

```
Push / PR
    │
    ▼
┌─────────┐
│  lint   │  Vérifie le style et les erreurs statiques (ESLint)
└────┬────┘
     │ (échoue si erreurs)
     ▼
┌─────────┐
│  test   │  Lance les tests Jest + génère le rapport de couverture (artefact)
└────┬────┘
     │ (échoue si tests KO)
     ▼
┌─────────┐
│  build  │  Build l'image Docker et push sur GHCR (seulement sur main)
└─────────┘
```

---

## Détail des jobs

### Job `lint`
- **Runner** : `ubuntu-latest`
- **Steps** : checkout → setup Node 20 (avec cache npm) → `npm ci` → `npm run lint`
- **Déclencheur** : tous les pushs et toutes les PR
- **Effet** : bloque la suite si ESLint détecte des erreurs

### Job `test`
- **Runner** : `ubuntu-latest`
- **Dépend de** : `lint` (via `needs: lint`)
- **Steps** : checkout → setup Node 20 (avec cache npm) → `npm ci` → `npm run test:coverage` → upload artifact
- **Artefact** : rapport de couverture publié sous `coverage-report`
- **Déclencheur** : tous les pushs et toutes les PR

### Job `build`
- **Runner** : `ubuntu-latest`
- **Dépend de** : `test` (via `needs: test`)
- **Steps** : checkout → setup Buildx → login GHCR → build + push
- **Conditions** : le push sur GHCR ne s'exécute que sur `main` (`github.ref == 'refs/heads/main'`)
- **Cache** : layers Docker via cache GitHub Actions (BuildKit GHA)
- **Tags** :
  - `ghcr.io/<owner>/taskboard:latest`
  - `ghcr.io/<owner>/taskboard:<sha_commit>` (traçabilité)

---

## Événements déclencheurs

| Événement | Lint | Test | Build | Push image |
|---|---|---|---|---|
| Push sur n'importe quelle branche | ✅ | ✅ | ✅ | ❌ |
| Push sur `main` | ✅ | ✅ | ✅ | ✅ |
| Pull Request | ✅ | ✅ | ✅ | ❌ |

---

## Secrets GitHub requis

Aucun secret supplémentaire nécessaire — le `GITHUB_TOKEN` est automatiquement injecté par GitHub Actions avec les permissions `packages: write`.
