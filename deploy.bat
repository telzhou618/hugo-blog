echo 'build'
git pull
hugo -D


echo 'deploy'
cd public
git init
git remote add origin https://github.com/telzhou618/telzhou618.github.io
git add -A
git commit -m "updated"
git push -u origin main

echo 'Successful'