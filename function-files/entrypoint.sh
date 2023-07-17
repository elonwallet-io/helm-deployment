#!/bin/sh

chown -R nonroot:nonroot /data
su - nonroot
exec "$@"
