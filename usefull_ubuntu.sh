#!/usr/bin/env bash

# dpkg  - list installed packages
dpkg -l | grep -qw curl || apt update && apt install -y curl