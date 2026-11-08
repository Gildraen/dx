# dx - Guide agent de developpement

Ce repository est le developpement du produit `dx` lui-meme : la Feature Dev
Container et l'integration des composants partages avec les autres repos
Gildraen.

Ce fichier concerne le developpement de `dx`. Il ne doit pas etre copie dans
les repositories consommateurs — voir [docs/consumer.md](docs/consumer.md)
pour le bootstrap consommateur.

## Role

- Source canonique de la Feature DX et de son integration
  — voir [docs/architecture.md](docs/architecture.md).
- Les instructions partagees et skills generiques destinees aux consommateurs
  vivent dans `Gildraen/dx-agents`, accessible ici par le sous-module
  `.devcontainer/components/agents/`. Les outils et Taskfiles vivent dans
  `Gildraen/dx-tools`, sous `.devcontainer/components/tools/`.
- Le socle d'outils commun reste volontairement limite : un outil y entre
  seulement s'il est un contrat DX ou un besoin durable de la plupart des
  projets, jamais seulement par commodite.

## Chargement des ressources IA

Avant toute intervention, lire
[.devcontainer/components/agents/AGENTS.md](.devcontainer/components/agents/AGENTS.md)
qui porte les regles communes et la delegation aux sous-agents.
Pour le developpement de `dx`, ce chemin local fait autorite ;
`DX_AGENTS_HOME` designe ce sous-module. S'il manque, executer
`git submodule update --init --recursive` a la racine du depot.

## Commandes utiles

```sh
task --list
task validate
task test
task feature:test
```
