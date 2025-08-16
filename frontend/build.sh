#!/bin/bash

# Install dependencies
npm i;
# Build dist dir
npm run build;
# Add libraries to dist dir
cp -R lib dist/lib;