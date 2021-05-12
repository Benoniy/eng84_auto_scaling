#!/bin/bash

cd /home/ubuntu/eng84_cicd/app/seeds
nodejs seed.js

sudo systemctl stop webapp
sudo systemctl start webapp