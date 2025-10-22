cd D:\software\pkmn-wfc-server
docker-compose down -v --rmi all --volumes --remove-orphans
docker volume prune -f
docker compose up -d --build
pause
