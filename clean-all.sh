#!/bin/bash
# raspdacmini-builds clean-all.sh
# Remove all build outputs

echo "Cleaning build outputs..."
rm -rf out/armhf/*
rm -rf out/arm64/*
echo "Done."
