---
name: git-workflow
description: Regles Git et workflow de contribution pour local-llm.
trigger: always
paths:
  - "**"
---

# Git workflow

## Objectif

Definir le cadre Git minimal pour toute modification du repository.

## Regles

- Travailler sur une branche dediee, jamais directement sur `main`.
- Ne jamais commit ni push sans approbation explicite de l'utilisateur.
- Utiliser des messages de commit conventionnels (`<type>: <description courte>`) qui decrivent la decision.
- Ouvrir une PR vers `main` et s'assurer que la validation CI passe avant merge.
