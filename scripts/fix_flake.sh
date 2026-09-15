#!/bin/bash

# Set up flake.nix
sudo docker run --rm -v "$PWD:/workspace" -w /workspace rust:latest \
    cargo build --release --manifest-path ./install-rs/Cargo.toml

sudo docker run --rm -v "$PWD:/workspace" -w /workspace rust:latest \
    ./install-rs/target/release/install-rs "$USER" "flake.nix"
