# Task 8 : Static IaC Security Scanning & CI/CD Pipelines

Pipeline DevSecOps "shift left" : le code Terraform et les commits sont scannés
**avant** tout déploiement. Si un scan échoue, rien n'est déployé.
Infra cible : un bucket S3 sur **LocalStack** (aucun compte AWS, aucun coût).

## Architecture

```
Pull Request / push
   ├── Gitleaks  (secrets dans l'historique git)
   ├── Checkov   (misconfigurations Terraform)
   └── Terraform plan -> apply (LocalStack)   needs: [Gitleaks, Checkov]
                                              apply uniquement sur main
```

## Décisions clés

| Décision | Choix | Pourquoi |
|---|---|---|
| Scanner IaC | Checkov | Plus de règles que tfsec |
| Cible | LocalStack 3.8.1 | Pas de compte AWS, gratuit |
| Gating | `needs` + branch protection | Terraform ne tourne que si les scans passent ; Gitleaks et Checkov obligatoires sur `main` |
| Workflow | `.github/workflows/` à la racine | GitHub ne lit que ce dossier |
| Fausse clé | Générée à l'exécution | Aucun secret littéral dans le dépôt |
| Bonus OIDC | Non | Exige un vrai compte AWS |

## Commandes

```bash
./demo.sh        # rejoue toutes les preuves (étapes 0 à 5)
./scan.sh [dir]  # Checkov seul (défaut: terraform/good)
```

## Résultats observés

| Étape | Résultat |
|---|---|
| Checkov sur `good` | 11 passed, 0 failed, 5 skipped, exit 0 |
| Checkov sur `bad` | 8 failed (dont CKV_AWS_20), exit 1 |
| Terraform plan + apply (LocalStack) | bucket créé, AES256, exit 0 |
| Gitleaks, fausse clé AWS | `aws-access-token` détecté, exit 1 |
| Gitleaks, dossier de la tâche | no leaks found, exit 0 |
| Run CI sur `main` | Gitleaks, Checkov, Terraform plan/apply : success |

## Preuves de blocage (PR laissées ouvertes)

| PR | Contenu | Résultat |
|---|---|---|
| [#1](https://github.com/AbdelKarim-Ensi/elevvo-devops-internship/pull/1) | Fausse clé AWS (générée, factice) | Gitleaks en échec, Terraform skipped, merge `BLOCKED` |
| [#2](https://github.com/AbdelKarim-Ensi/elevvo-devops-internship/pull/2) | S3 public non chiffré | Checkov en échec, Terraform skipped, merge `BLOCKED` |

Ces PR ne doivent jamais être mergées : elles existent uniquement comme preuve.

## Problèmes rencontrés

- **pip install checkov** : coupure réseau, relancé avec `--default-timeout=120 --retries 10`.
- **Lifecycle S3 sur LocalStack** : l'`apply` bloquait (timeout 3 min). Ressource retirée, check `CKV2_AWS_61` ignoré avec justification.
- **Gitleaks flaggait `demo.sh`** : la fausse clé littérale était dans le dépôt. Elle est maintenant générée à l'exécution, au format AWS réel (sinon seule la règle `generic-api-key` se déclenchait).
- **Push du workflow refusé** : jeton sans permission `workflow`. Réglé avec `gh auth refresh -s workflow`.
- **GitHub push protection** : a bloqué le push de la fausse clé avant la CI (deuxième couche de défense). Clés factices autorisées pour la démo.

## Fichiers

- `terraform/good/main.tf` : S3 conforme (versioning, chiffrement, public access block)
- `terraform/bad/main.tf` : S3 volontairement mauvais, ne jamais appliquer
- `scan.sh`, `demo.sh`
- `linkedin_post.md`
- `../.github/workflows/task-08-iac-security.yml`
