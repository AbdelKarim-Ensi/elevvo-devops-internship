# Task 5 - Multi-Stage Docker + Private Network

```bash
cp .env.example .env
docker compose up -d --build
curl localhost:3000                       # {"message": ..., "visits": 1}
docker compose ps                         # db has NO published port
docker compose exec api id                # uid=1000(node) -> not root
docker images elevvo-api:1.0              # image size
nc -zv localhost 27017                    # must FAIL (db not exposed)
docker network inspect task-05-docker-multistage_private | grep -i internal
```

## Bonus: Trivy
```bash
bash scan.sh
```

## Adapt to Cyber Park HR
Replace `app/` by your Express backend (keep `/health`) and keep Dockerfile + compose as is.
