# dx - Guide agent de developpement

Ce repository est le developpement du produit `dx` lui-meme : la Feature Dev
Container, les workflows reusable, le preset Renovate et le runtime DX
partages avec les autres repos Gildraen.

Ce fichier concerne le developpement de `dx`. Il ne doit pas etre copie dans
les repositories consommateurs — voir [docs/consumer.md](docs/consumer.md)
et [examples/consumer/AGENTS.md](examples/consumer/AGENTS.md) pour le
bootstrap consommateur.

## Role

- Source canonique de la DX partagee (Feature, reusable workflows, preset
  Renovate, runtime) — voir [docs/architecture.md](docs/architecture.md).
- Les regles agent generiques destinees aux consommateurs vivent dans
  `.devcontainer/src/dx/runtime/agents/` (`base.md`, `git.md`), pas ici.
- Le socle d'outils commun reste volontairement limite : un outil y entre
  seulement s'il est un contrat DX ou un besoin durable de la plupart des
  projets, jamais seulement par commodite.

## Regles de contribution

- Travailler sur une branche dediee, jamais directement sur `main`.
- Ne jamais commit ni push sans validation explicite de l'utilisateur.
- Self-review du diff complet avant toute publication (voir
  [.devcontainer/src/dx/runtime/agents/git.md](.devcontainer/src/dx/runtime/agents/git.md)).
- Ouvrir une PR vers `main` et attendre la CI avant merge.

## Commandes utiles

```sh
task --list
task validate
task test
task feature:test
task status
```
