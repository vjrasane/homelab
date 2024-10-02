#!/bin/bash

docker compose exec -T paperless document_exporter /usr/src/paperless/export
