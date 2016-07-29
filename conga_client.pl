#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use WWW::Curl::Easy;
use JSON::XS;
use Data::Dumper;
use Try::Tiny;

## process cli args ##

# set default values for args
my $help = "help";
my $command = "";

# auth args
my $user = "";
my $project = "";
my $resource = "";
my $keyfile = "";

# alloc args
my $src = "";
my $dest = "";
my $duration = 0;

GetOptions(
	'command=s' => \$command, 'help:s' => \$help, 'keyfile=s' => \$keyfile,
	'user=s' => \$user, 'project=s' => \$project, 'resource=s' => \$resource,
	'src=s' => \$src, 'dest=s' => \$dest, 'duration=i' => \$duration
);

# check help option
if($help ne "help")
{
	do_help($help);
}

# init curl
my $curl = WWW::Curl::Easy->new;
my $headers="";
my $body;

# check command option
if($command ne "")
{
	# auth
	if($command eq "auth")
	{
		# if all auth args have a value
		if($keyfile ne "" and $user ne "" and $project ne "" and $resource ne "")
		{
			# set data for auth request
			my %data;
			$data{"user_id"} = $user;
			$data{"project_id"} = $project;
			$data{"resource_id"} = $resource;

			# encode data as json string
			my $json_text = encode_json \%data;

			# check we can write to keyfile before issuing request
			write_api_key("", $keyfile);

			conga_auth($json_text);
		} else
		{
			print "auth command failed to find all the required options.\n";
			print "Provided options:\nkeyfile: $keyfile\nuser: $user\nproject: $project\nresource: $resource\n\n";
			do_help($command);
		}
	}

	# alloc
	elsif($command eq "alloc")
	{
		# if all alloc args have a value
		if($keyfile ne "" and $src ne "" and $dest ne "" and $duration != 0)
		{
			# read apikey from keyfile
			my $key = read_api_key($keyfile);

			print "key is: '$key'\n\n";

			# set data for alloc request
			my %data;
			$data{"api_key"} = $key;
			$data{"src_ip"} = $src;
			$data{"dst_ip"} = $dest;
			$data{"duration"} = $duration;

			# encode data as json string
			my $json_text = encode_json \%data;

			conga_alloc($json_text);
		} else
		{
			print "alloc command failed to find all the required options.\n";
			print "Provided options:\nkeyfile: $keyfile\nsrc: $src\ndest: $dest\nduration: $duration\n\n";
			do_help($command);
		}

	}

	# dealloc
	elsif($command eq "dealloc")
	{
		print "run dealloc\n";
	}

	# unrecongized
	else
	{
		print "The command '$command' is not recongized.\n";
	}
}
 

## subroutines for sending conga commands ##

# subroutine to authenticate with conga
sub conga_auth
{
	my ($json_str) = @_;
	my $curl = WWW::Curl::Easy->new;

	# set transfer options
	$curl->setopt(CURLOPT_HTTPHEADER, ['Content-type: application/json']);	# sending JSON text
	$curl->setopt(CURLOPT_HEADER, 0);					# do no include header in body
	$curl->setopt(CURLOPT_URL, 'https://limbo.psc.edu:13500/auth');		# Target URL
	$curl->setopt(CURLOPT_CUSTOMREQUEST, "POST");				# Requesting POST
	$curl->setopt(CURLOPT_POSTFIELDS, $json_str);				# our data as json string
	$curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);				# limbo.psc.edu fails security check
	
	# A filehandle, reference to a scalar or reference to a typeglob can be used here.
	my $response_body;
	# set write callback
	$curl->setopt(CURLOPT_WRITEFUNCTION, \&process_auth_response);
	$curl->setopt(CURLOPT_WRITEHEADER, \$headers);
	$curl->setopt(CURLOPT_FILE, \$body);
	
	print("performing auth request..\n");
	 
	# Starts the actual request
	my $retcode = $curl->perform;
	
	#print("return code: $retcode\n");
	 
	# Looking at the results
	if ($retcode == 0)
	{
	        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	        print("Transfer passed with response code: $response_code\n--\n");
	        # judge result and next action based on $response_code
	        #print("Received response:\n- v -\n$response_body\n- ^ -\n");
	} else
	{
	        # Error code, type of error, error message
	        print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	}

	return $retcode;
}

# subroutine to request allocation with conga
sub conga_alloc
{
	my ($json_str) = @_;

	# set transfer options
	$curl->setopt(CURLOPT_HTTPHEADER, ['Content-type: application/json']);	# sending JSON text
	$curl->setopt(CURLOPT_HEADER, 0);					# do no include header in body
	$curl->setopt(CURLOPT_URL, 'https://limbo.psc.edu:13500/allocations');	# Target URL
	$curl->setopt(CURLOPT_CUSTOMREQUEST, "POST");				# Requesting POST
	$curl->setopt(CURLOPT_POSTFIELDS, $json_str);				# our data as json string
	$curl->setopt(CURLOPT_SSL_VERIFYPEER, 0);				# limbo.psc.edu fails security check
	
	# A filehandle, reference to a scalar or reference to a typeglob can be used here.
	my $response_body;
	# set write callback
	$curl->setopt(CURLOPT_WRITEFUNCTION, \&process_alloc_response);
	$curl->setopt(CURLOPT_WRITEHEADER, \$headers);
	$curl->setopt(CURLOPT_FILE, \$body);
	
	print("performing alloc request..\n");
	 
	# Starts the actual request
	my $retcode = $curl->perform;
	
	print("return code: $retcode\n");
	 
	# Looking at the results
	if ($retcode == 0)
	{
	        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	        print("Transfer passed with response code: $response_code\n--\n");
	        # judge result and next action based on $response_code
	        #print("Received response: $response_body\n--\n");
	} else
	{
	        # Error code, type of error, error message
	        print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	}

	return $retcode;
}



## handlers for conga messages ##

# basic callback function. Stores data in user-defined pointer.
sub chunk { my ($data,$pointer)=@_; ${$pointer}=$data; print "test ".$body."\n"; return length($data) }

## conga messages should have the following strcuture:
#	{
#		"status": 0,
#		"results": [
#		{
#		  "resource_id": 'blacklight.psc.teragrid',
#		  "end_time": 1469819312,
#		  "start_time": 1469646512,
#		  "user_id": 'blearn',
#		  "api_key": 'vg9apzmepufdjtkj',
#		  "project_id": 'TG-MCB110157'
#		}]
#	}

# callback that handles conga auth responses
sub process_auth_response
{
	my ($data, $pointer) = @_;

	# decode json text data into json hash object
	try
	{
		my $res_ref = decode_json $data;
		my %res = %$res_ref;
	

		# examine auth response for success code
		if($res{'status'} == 0) 	# successful
		{
			print "Auth worked\n";
			# write api key
			write_api_key($res{'results'}[0]{'api_key'}, $keyfile);
		} else				# failed
		{
			print "Auth failed\n";
			print "Error response from CONGA server.\n";
			print "Status code: $res{'status'} \nError message(s): $res{'errors'}\n\n";
		}
	} catch
	{
		print "Failed to parse JSON object from CONGA.\n";
		warn "Caught error: $_\n\n";
		warn Dumper(\$data)."\n\n";
	};
	#print("api_key is: $res{'results'}[0]{'api_key'}\n");

	#${$pointer}=%res;	# copy received data into user-defined pointer

	#print Dumper(\%res)."\n";

	# cleanup curl handle
	$curl->cleanup();

	return length($data);
}

# callback that handles conga alloc responses
sub process_alloc_response
{
	my ($data, $pointer) = @_;

	# decode json text data into json hash object
	try
	{
		my $res_ref = decode_json $data;
		my %res = %$res_ref;
	
	
		# examine alloc response for success code
		if($res{'status'} == 0) 	# successful
		{
			print "Alloc worked\n";
		} else				# failed
		{
			print "Alloc failed\n";
			print "Error response from CONGA server.\n";
			print "Status code: $res{'status'} \nError message(s): $res{'errors'}\n\n";
		}
	} catch
	{
		print "Failed to parse JSON object from CONGA.\n\n";
		warn "Caught error: $_\n\n";
		warn Dumper(\$data)."\n\n";
	};
	#${$pointer}=%res;	# copy received data into user-defined pointer

	#print Dumper(\%res)."\n";

	# cleanup curl handle
	$curl->cleanup();

	return length($data);
}

## subroutines for maintaining state ##
sub write_api_key
{
	my ($_key, $_keyfile) = @_;

	# open _keyfile; write _key; close _keyfile
	if(-e $_keyfile) # if file exists, overwrite file
	{
		open(KEYFILE, "> $_keyfile") || die "failed to open '$_keyfile'\n\n";
		print KEYFILE $_key;
		close(KEYFILE);
	} else # if file doesn't exist, append file (creates new file)
	{
		open(KEYFILE, ">> $_keyfile") || die "failed to open '$_keyfile'\n\n";
		print KEYFILE $_key;
		close(KEYFILE);
	}
	return;
}

sub read_api_key
{
	my ($_keyfile) = @_;
	my $_key;

	# open _keyfile; read contains into _key; close _keyfile; return _key
	if(-e $_keyfile) # if file exists, read from file
	{
		open(KEYFILE, "< $_keyfile") || die "failed to open $_keyfile\n\n";
		$_key = <KEYFILE>;
		close(KEYFILE);
	} else # if file doesn't exist, fail because we need an apikey
	{
		die "Keyfile '$_keyfile' does not exist. Please provide a valid keyfile.\n\n";
	}

	return $_key;
}

# help text subroutine
sub do_help
{
	my ($cmd) = @_;
	my %help = (); # build hash of help text for each command
	$help{"help"} = "Usage: $0 --command [ auth | alloc | ... ] [--help [<command>] ]\nEach command requires it's own cli options. See --help <command> for more information.\n\n";
	$help{"auth"} = "Usage: $0 --command auth --user <usr_id> --project <proj_id> --resource <res_id> --keyfile </path/to/keyfile>\nIf successful, the api key will be written to the keyfile.\n\n";
	$help{"alloc"} = "Usage: $0 --command alloc --keyfile <key_file> --src <src_ip> --dest <dest_ip> --duration <seconds>\nKeyfile is a text file that contains the apikey.\n\n";

	if(exists $help{$cmd})
	{
		print $help{$cmd};
	} else
	{
		print $help{"help"};
	}
	exit;
}
