## Quoi
<!-- Ce que change cette PR (fichiers / modules / rôles concernés) -->

## Pourquoi
<!-- Le besoin ou le problème résolu -->

## Comment tester
<!-- Commandes lancées, résultats observés (terraform plan, ansible-playbook, captures) -->

## Checklist
- [ ] `terraform fmt -recursive` et `terraform validate` OK
- [ ] Aucun secret, state, `.pem` ou `.tfvars` sensible dans le diff
- [ ] Aucune valeur propre à un environnement codée en dur dans un module
- [ ] Commits au format `type(scope): description`
- [ ] Relecteur assigné (un autre membre que l'auteur)
