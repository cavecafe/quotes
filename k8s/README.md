
Run this command to create a secret in the same namespace as the service account:

* create .env file with the following content:
```
namespace=<namespace_of_the_project>
docker_username=<your_dockerhub_username>
docker_password=<your_dockerhub_token>
docker_email=<your_email@email.com>
host_name=<your_dns_hostname (i.e. api.yourdomain.com)>
target_port=8080
exposed_port=80
node_port=30090
replicas=1
image_repository=<dockerhub-user>/<registry-name>
image_tag=latest
run_as_user=<UID (ex. 1001)>
run_as_group=<GID (ex. 3000)>
memory_request=32Mi
cpu_request=60m

```

* Run the following command:
> ./setup-spring-boot.sh
