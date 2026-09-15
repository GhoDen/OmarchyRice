git fetch origin
git reset --hard origin/main

sh ./fix_flake.sh

home-manager switch --flake .
