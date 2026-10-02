# NeoCargo TrackFleet — Plateforme multi-environnements (TP de groupe IPSSI)

Infrastructure AWS (VPC 3 niveaux, ALB + ASG, RDS PostgreSQL, S3) déployée en
**deux environnements isolés, staging et prod**, à partir des **mêmes modules
Terraform**, puis configurée par des **rôles Ansible**.

- Schéma d'architecture : [`docs/architecture.md`](docs/architecture.md)
- Rapport d'équipe : [`docs/rapport.md`](docs/rapport.md)

## Arborescence

```
.
├── terraform/
│   ├── modules/
│   │   ├── network/      VPC, sous-réseaux, NAT, routage, security groups
│   │   ├── compute/      Launch Template, ALB, Target Group, ASG, bastion
│   │   └── data/         RDS PostgreSQL, S3, mot de passe généré
│   └── environments/
│       ├── staging/      main.tf + terraform.tfvars + state local
│       └── prod/         main.tf + terraform.tfvars + state local
├── ansible/
│   ├── ansible.cfg
│   ├── requirements.yml  collections amazon.aws + community.general
│   ├── site.yml
│   ├── inventory/aws_ec2.yml
│   ├── group_vars/       app.yml, staging.yml, prod.yml
│   ├── roles/            common, webserver, monitoring
│   └── scripts/tf_env.sh charge les outputs Terraform d'un environnement
├── docs/                 schéma + rapport
├── .github/              CI (bonus) + modèle de Pull Request
└── .gitignore
```

## Prérequis

- Terraform >= 1.5 **ou OpenTofu** (`tofu`, mêmes commandes) si le registre
  HashiCorp est inaccessible depuis votre pays.
- Ansible >= 2.15 (sous Linux / WSL) + `pip install boto3 botocore`
- Identifiants **AWS Academy Learner Lab** (*AWS Details → AWS CLI*) exportés :
  `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (valables ~4 h).
- Une paire de clés EC2 dans **eu-west-3** de votre compte. Par défaut
  `key_name = "ipssi-tp"` ; sinon : `terraform apply -var key_name=ma-cle`.

## Déployer un environnement

Chaque environnement est un dossier indépendant avec son propre state :
**l'environnement visé = le dossier dans lequel vous êtes.**

```bash
cd terraform/environments/staging     # ou prod
terraform init
terraform plan
terraform apply
terraform output                      # URL de l'ALB, IP du bastion, endpoint RDS…
```

> ⚠️ Une seule personne applique un environnement donné (le state est local à
> sa machine). Annoncez-le à l'équipe avant un apply.

## Configurer avec Ansible

```bash
cd ansible
export ANSIBLE_CONFIG=$PWD/ansible.cfg   # obligatoire si le dépôt est sur /mnt/c (WSL)
ansible-galaxy collection install -r requirements.yml
export NEOCARGO_SSH_KEY=~/.ssh/ipssi-tp.pem   # chmod 600 sur la clé

source scripts/tf_env.sh staging             # charge RDS_HOST, RDS_PASSWORD… en mémoire
ansible-inventory --graph                    # vérifie les groupes staging/prod/app/bastion
ansible-playbook site.yml -e target_env=staging
ansible-playbook site.yml -e target_env=staging   # 2e passage : changed=0 (idempotence)
```

Puis ouvrez l'URL `alb_url` : la page affiche l'environnement, l'instance et
l'état de la connexion RDS.

## Contribuer (règles d'équipe)

1. `git switch main && git pull` puis `git switch -c feat/ma-fonctionnalite`
2. Commits au format `type(scope): description` (ex : `feat(network): ajoute la NAT`)
3. `terraform fmt -recursive` avant de pousser
4. Pull Request vers `main` (remplir le modèle), **au moins 1 approbation** d'un autre membre
5. Ne jamais supprimer une branche ou une PR après merge

## Nettoyage (obligatoire en fin de séance)

```bash
cd terraform/environments/staging && terraform destroy
cd ../prod && terraform destroy
```

Vérifier ensuite dans la console AWS qu'il ne reste ni EC2, ni RDS, ni ALB, ni NAT Gateway / Elastic IP.
