#!/usr/bin/env bash
# Charge dans le shell courant les outputs Terraform d'un environnement,
# pour qu'Ansible les lise (group_vars/app.yml). Le mot de passe RDS reste
# en mémoire, il n'est jamais écrit sur le disque ni dans le dépôt.
#
# Usage (depuis ansible/) :  source scripts/tf_env.sh staging|prod

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "Ce script doit être sourcé : source scripts/tf_env.sh <staging|prod>" >&2
  exit 1
fi

_env="$1"
if [ "$_env" != "staging" ] && [ "$_env" != "prod" ]; then
  echo "Usage : source scripts/tf_env.sh <staging|prod>" >&2
  return 1
fi

# terraform ou OpenTofu (tofu), selon ce qui est installé
_tf=$(command -v terraform || command -v tofu)
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../terraform/environments/$_env" && pwd)"

_out() { "$_tf" -chdir="$_dir" output -raw "$1"; }

export NEOCARGO_ENV="$_env"
export RDS_HOST="$(_out rds_address)"
export RDS_DB_NAME="$(_out db_name)"
export RDS_USER="$(_out db_username)"
export RDS_PASSWORD="$(_out db_password)"

echo "Variables chargées pour l'environnement : $NEOCARGO_ENV"
echo "  RDS_HOST    = $RDS_HOST"
echo "  RDS_DB_NAME = $RDS_DB_NAME"
echo "  ALB         = $(_out alb_url)"
echo "  Bastion     = $(_out bastion_public_ip)"
unset _env _tf _dir
unset -f _out
