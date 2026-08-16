# dx - Guide agent de developpement

Ce repository centralise la baseline DX partagee entre les repos Gildraen.

## Role

- Source canonique pour les fichiers DX communs
- Workflows CI de maintenance/validation
- Detection de drift via `dx-coherence`

## Regles de contribution

- Travailler sur une branche dediee, jamais directement sur `main`.
- Ne jamais commit ni push sans validation explicite de l'utilisateur.
- Ouvrir une PR vers `main` et attendre la CI avant merge.

## Commandes utiles

```sh
task --list
task install-tools
task validate
task status
```
