#!/bin/bash

echo "=================================================="
echo "GIT FETCH & CONFIGURATION"
echo "=================================================="
echo ""
if [ -z "$(git config user.name)" ]; then
  git config user.name "WordPress Backup Bot"
fi
if [ -z "$(git config user.email)" ]; then
  git config user.email "bot@mail.com"
fi
git config pull.default current
git config push.default current
git config core.filemode false
git checkout "$GIT_MAIN_BRANCH_NAME"
git pull
git pull --tags