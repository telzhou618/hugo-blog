echo 'deploy start...'
rm -rf public
hugo -D
cp -rf public/* deploy/
cd deploy
git add -A
git commit -m "updated"
git push -u origin main

echo 'Successful！！！'