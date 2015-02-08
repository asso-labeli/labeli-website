git reset --hard HEAD
git pull >> hook.log
chmod u+x hook.sh
vulcanize -o index.html website.html
npm update
bower update
forever restart server.js