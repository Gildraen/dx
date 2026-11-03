# dx - Guide agent de developpement

Ce repository est le developpement du produit `dx` lui-meme : la Feature Dev
Container, les workflows reusable, le preset Renovate et le runtime DX
partages avec les autres repos Gildraen.

Ce fichier concerne le developpement de `dx`. Il ne doit pas etre copie dans
les repositories consommateurs — voir [docs/consumer.md](docs/consumer.md)
pour le bootstrap consommateur.

## Role

- Source canonique de la DX partagee (Feature, reusable workflows, preset
  Renovate, runtime) — voir [docs/architecture.md](docs/architecture.md).
- Les instructions partagees et skills generiques destinees aux consommateurs
  vivent dans `.devcontainer/src/dx/runtime/instructions/`,
  `.devcontainer/src/dx/runtime/agents/` et
  `.devcontainer/src/dx/runtime/skills/`, pas ici.
- Le socle d'outils commun reste volontairement limite : un outil y entre
  seulement s'il est un contrat DX ou un besoin durable de la plupart des
  projets, jamais seulement par commodite.

## Chargement du runtime

Avant toute intervention, lire
[.devcontainer/src/dx/runtime/AGENTS.md](.devcontainer/src/dx/runtime/AGENTS.md)
qui porte les regles communes et la delegation aux sous-agents.
Pour le developpement de `dx`, ce
chemin local fait autorite ; le devcontainer definit egalement `DX_HOME` sur
ce runtime.

## Commandes utiles

```sh
task --list
task validate
task test
task feature:test
task status
```
