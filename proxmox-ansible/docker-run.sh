docker compose up -d

docker exec -it ansible_container ansible all -m ping -i inventory.yml -k

docker compose down