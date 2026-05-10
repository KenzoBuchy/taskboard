# Étape 1 — Gestion des secrets

## c'est quoi un secret ?

c'est une valeur qui donne accès à quelque chose et que personne d'autre que l'app doit connaître. dans ce projet y'en a deux :

- `JWT_SECRET` : sert à signer les tokens, si quelqu'un la connaît il peut créer des tokens valides et se co en tant que n'importe qui
- `DATABASE_URL` : contient le mot de passe postgres, avec ça on peut lire/modifier/supprimer toute la base

## pourquoi c'est dangereux même en repo privé ?

- un repo privé peut devenir public par erreur (ça arrive)
- tous les devs ont accès au repo, pas forcément à la prod → avec les secrets dans le code tout le monde les a
- les outils connectés au repo (github actions, sonar, dependabot...) voient aussi le code donc les secrets
- et surtout : même si on change le secret plus tard, l'ancien reste dans l'historique git

## comment savoir si des secrets ont déjà leaké dans l'historique ?

on peut chercher à la main :
```bash
git log --all -p | grep -i "secret\|password\|jwt"
```

mais y'a des outils faits pour ça :
```bash
gitleaks detect --source .
trufflehog git file://.
```

dans notre cas c'est simple, le .env était là dès le premier commit donc le secret est dans l'historique depuis le début

## si on supprime le .env mais que le commit initial reste ?

ça change rien. git supprime pas les données, il ajoute juste des commits. le .env du premier commit est toujours accessible :

```bash
git show bc361c6:.env  # ramène le contenu complet
```

pour vraiment effacer il faudrait réécrire l'historique avec `git filter-repo` ou BFG Repo Cleaner, mais même là si quelqu'un a cloné le repo avant il a encore l'ancien historique sur sa machine.

**conclusion : dès qu'un secret est commité il faut le considérer comme compromis et le changer, point.**

## ce qu'on a fait

- ajouté `.env` dans `.gitignore`
- retiré `.env` du tracking git (`git rm --cached .env`)
- le `JWT_SECRET` dans l'historique est grillé, à changer
