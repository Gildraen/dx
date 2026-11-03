---
name: tests-complete
description: 'Ecrire ou completer les tests et scripts de test pour combler des lacunes de couverture deja identifiees (par exemple via tests-audit), avec preuve rouge/vert et validation du projet ; a utiliser par dx-tests pour implementer une suite de tests.'
---

# Completion de la suite de tests

## Quand l'utiliser

Utiliser ce skill lorsque des lacunes de couverture sont deja identifiees
(par exemple par `tests-audit`) ou explicitement demandees, et qu'il faut
ecrire ou completer les tests et scripts de test correspondants. Ce mode est
mutatif : il modifie le projet.

## Procedure

1. Reprendre la liste des lacunes priorisees ou, a defaut, le perimetre
   explicitement demande.
2. Reutiliser les frameworks, runners et conventions de test deja en place
   plutot que d'en introduire de nouveaux sans justification explicite.
3. Ecrire ou completer les tests et scripts de test necessaires en verifiant
   qu'ils echouent sans le comportement attendu et passent avec.
4. Executer les commandes de validation du projet (par exemple `task test`,
   `task validate`) pour confirmer que les tests ajoutes ou modifies passent
   et n'affaiblissent aucun test existant.
5. Documenter explicitement les zones sciemment laissees sans test (limite
   technique, cout disproportionne) plutot que de les omettre silencieusement.

## Contraintes

- Ne jamais affaiblir, desactiver ou skipper un test existant pour le faire
  passer.
- Ne pas introduire un nouveau framework ou outil de test sans verifier
  qu'aucun outil deja adopte ne convient et sans le justifier explicitement.
- Un test doit verifier un comportement observable, pas un detail
  d'implementation fragile.
- Ne pas depasser le perimetre des lacunes retenues sans le signaler.

## Sortie attendue

Liste des tests et scripts ajoutes ou completes avec leur intention, preuve
que la suite echoue sans le correctif/comportement et passe avec, validations
executees, et zones restant sans test avec leur justification.
