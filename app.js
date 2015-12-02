var connectionScriptPath = '/home/lfreneda/lfreneda/vpn/auto-hma-openvpn.sh';

function run_cmd(cmd, args, cb, end) {
    var spawn = require('child_process').spawn,
        child = spawn(cmd, args),
        me = this;
    child.stdout.on('data', function (buffer) { cb(me, buffer) });
    child.stdout.on('end', end);
}

run_cmd(
    'bash', [connectionScriptPath],
    function (me, buffer) {
        if (buffer) {
            var line = buffer.toString();
            line = line.replace('\n', '');
            if (line && line != '') {
                console.log(line);
            }
        }
    },
    function () {

    }
);
