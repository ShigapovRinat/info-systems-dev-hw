#!/bin/bash
set -e

# Установка Docker
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker

# Запуск контейнера
sudo docker run -d -p 80:8080 --name bookstore jmix/jmix-bookstore
