git reset --hard HEAD
git pull >> hook.log
chmod u+x hook.sh
npm update
bower update
forever restart server.js