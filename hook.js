var gith = require('gith').create(9002);

var execFile = require('child_process').execFile;

gith({repo: 'asso-labeli/labeli-website'}).on('all', function(payload)
{
    if(payload.branch === 'master')
        execFile('./hook.sh');
});