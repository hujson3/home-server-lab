#!/bin/bash

set -e

DATE=$(date +%F_%H-%M)
DEST="/opt/backups/$DATE"

mkdir -p "$DEST"


echo "=== Backup homelabu: $DATE ==="

mkdir -p "$DEST/compose"

cp /opt/portainer/compose.yaml "$DEST/compose/portainer.yaml"
cp /opt/uptime-kuma/compose.yaml "$DEST/compose/uptime-kuma.yaml"
cp /opt/adguardhome/compose.yaml "$DEST/compose/adguardhome.yaml"
cp /opt/glances/compose.yaml "$DEST/compose/glances.yaml"

tar -czf "$DEST/adguardhome.tar.gz" \
	-C /opt/adguardhome conf work


PORTAINER_VOLUME=$(docker inspect portainer \
	--format '{{range .Mounts}}{{if  eq .Destination "/data"}}{{.Name}}{{end}}{{end}}')


KUMA_VOLUME=$(docker inspect uptime-kuma \
	--format '{{range .Mounts}}{{if eq .Destination "/app/data"}}{{.Name}}{{end}}{{end}}')

docker stop portainer

docker run --rm \
	-v "$PORTAINER_VOLUME":/data:ro \
	-v "$DEST":/backup \
	alpine \
	tar -czf /backup/portainer-data.tar.gz -C /data .

docker start portainer



docker stop uptime-kuma

docker run --rm \
	-v "$KUMA_VOLUME":/data:ro \
	-v "$DEST":/backup \
	alpine \
	tar -czf /backup/uptime-kuma-data.tar.gz -C /data .

docker start uptime-kuma

find /opt/backups -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} \;

echo "=== Backup zakonczony ==="

