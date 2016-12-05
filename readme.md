Lightweight client for the CONGA service.

Used to interact with CONGA via the CLI or batch jobs.

## Basic Usage ##
Basic Usage: ./conga_client.pl --command [ auth | alloc | ... ] [--help [<command>] ]
Each command requires its own cli options. See --help <command> for more information.

## Commands ##

Auth - Authenticates with CONGA server using XSEDE user ID and project ID. API key is store in keyfile which is used for future requests.
Usage: ./conga_client.pl --command auth --user <usr_id> --project <proj_id> --resource <res_id> --keyfile </path/to/keyfile>
If successful, the api key will be written to the keyfile.

Alloc - Sends a meter allocation request to the CONGA server. A valid API key must be read from the keyfile. 
Usage: ./conga_client.pl --command alloc --keyfile <key_file> --src <src_ip> --dest <dest_ip> --duration <seconds> --rate <Kbps>
Keyfile is a text file that contains the apikey.

Dealloc - CONGA server currently does not support deallocation of allocated resources.
