var gith = require('gith').create(9002);

var execFile = require('child_process').execFile;

gith({repo: 'eolhing/labeli-website'}).on('all', function(payload)
{
    if(payload.branch === 'master')
    {
        execFile('./hook.sh', function(error, stdout, stderr)
        {
            console.log('update complete');
        });
    }
});