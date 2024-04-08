#!/bin/bash

function failed() {
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
 }

 function addGitIgnore() {
   fileName=$1
   GITIGNORE=".gitignore"
   if [ -f "$GITIGNORE" ]; then
     echo "$GITIGNORE file exists"
   else
     echo "create $GITIGNORE for current directory"
     touch $GITIGNORE
   fi

   if grep -q "$fileName" "$GITIGNORE"; then
     echo "$fileName already exists in $GITIGNORE"
   else
     echo "$fileName" >> "$GITIGNORE"
     echo "$fileName entry to $GITIGNORE"
   fi
 }

 function downloadTemplate() {
   yml=$1
   repo="https://raw.githubusercontent.com/cavecafe/k8s-yml-template/main/dotnet/k8s"
   if [ -f "$yml" ]; then
     echo "$yml exists"
   else
     echo "$yml does not exist, downloading from $repo/$yml"
     echo "curl -o $yml $repo/$yml"
     curl -o "$yml" "$repo/$yml"
   fi
 }



mkdir -p template || failed "failed to create template directory"
#cd template || failed "failed to change directory to template"
downloadTemplate template/deployment.template.yml
downloadTemplate template/namespace.template.yml
downloadTemplate template/network.template.yml
downloadTemplate template/secret.template.yml
#cd ..

addGitIgnore .env
addGitIgnore .env.*
addGitIgnore .secret.*.yml
addGitIgnore .DS_Store

ENV=$1
echo "ENV: $ENV"
if [ -z "$ENV" ]; then
  failed "ENV is empty, ENV can be (DEV, QA, or PROD)"
fi

# Check if ENV is valid
if [ "$ENV" != "DEV" ] && [ "$ENV" != "QA" ] && [ "$ENV" != "PROD" ]; then
  failed "ENV can be (DEV, QA, or PROD)"
fi

# Check if .env file exists
if [ ! -f ".env.$ENV" ]; then
  echo "No .env.$ENV file found!"
  read -r -p "Create .env.$ENV file? (y/n) " confirm
  if [[ $confirm = "y" ]]; then
    touch .env."$ENV"
    echo "creating empty .env.$ENV file"
    cat <<EOF > ".env.$ENV"
namespace=
docker_username=
docker_password=
docker_email=
exposed_port=
target_port=
node_port=
host_name=
replicas=
image_repository=
image_tag=
run_as_user=
run_as_group=
memory_request=
cpu_request=
EOF
  else
    failed "confirmed not to create .env.$ENV file"
  fi
fi

mkdir -p "$ENV" || failed "failed to create $ENV directory"

env_file=".env.$ENV"
while IFS= read -r line; do
  key=$(echo "$line" | cut -d'=' -f1)
  value=$(echo "$line" | cut -d'=' -f2)
  echo "key: '$key', value: '$value'"

  if [ -z "$value" ]; then
    echo "*** value for $key is empty, skipped"
    # failed "value for $key is empty"
  fi
done < "$env_file"

echo ""
echo "updated .env.$ENV file:"
echo ""
while IFS= read -r line; do
  echo "$line"
done < "$env_file"

echo ""
read -r -p "write changes to $env_file? (y/n) " confirm
if [[ $confirm = "y" ]]; then
  while IFS= read -r line; do
    echo "$line"
  done < "$env_file" > temp && mv temp "$env_file"
  echo ".env.$ENV file updated!"
else
  failed "confirmed not to update .env.$ENV file"
fi

# Load values from .env file
source .env."$ENV"

# get value of the key namespace from .env file
NAMESPACE=$(grep namespace .env."$ENV" | cut -d'=' -f2)
echo "Namespace: $NAMESPACE"

# loop all *.yml files in the template directory
for file in template/*.template.yml; do
  # Read YAML into a variable
  yaml=$(cat "$file")

  # search all keys in .env file and replace the placeholders
  while IFS= read -r line; do
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2)
    if [ -z "$value" ]; then
      echo "*** value for $key is empty, skipped"
      # check if yaml contains the key
      if [[ $yaml == *"$key"* ]]; then
        failed "*** value for $key is empty, please update .env.$ENV file"
      fi
    else
      yaml=${yaml//\_\_\{$key\}\_\_/$value}
    fi
  done < "$env_file"

  # Write the output to a new file
  new_yml="${file//.template/}"
  new_yml="${new_yml//template\//}"
  echo "$yaml" > "$ENV/$new_yml"
  echo "created $ENV/$new_yml"
done

kubectl apply -f "$ENV"/namespace.yml || failed "failed to apply $ENV/namespace.yml"
kubectl apply -f "$ENV"/secret.yml || failed "failed to apply $ENV/secret.yml"
mv "$ENV"/secret.yml "$ENV"/.secret.yml

kubectl create namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/cloud/deploy.yaml || failed "failed to apply ingress-nginx"
echo "Waiting for ingress-nginx to be ready..."
sleep 10
kubectl apply -f "$ENV"/network.yml || failed "failed to apply $ENV/network.yml"
# deployment.yml will be used in the CI/CD pipeline
#kubectl apply -f "$ENV"/deployment.yml || failed "failed to apply $ENV/deployment.yml"
