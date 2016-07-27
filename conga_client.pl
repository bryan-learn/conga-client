#!/usr/bin/perl
use strict;
use warnings;
use WWW::Curl::Easy;
use JSON::XS;
use Data::Dumper;

print "start script\n";

my $headers="";
my $body;

# init curl
my $curl = WWW::Curl::Easy->new;

# set initial data for request
my %data;
$data{'user_id'} = "blearn";		# TODO these values should be read from cli args
$data{"project_id"} = "TG-MCB110157";
$data{"resource_id"} = "blacklight.psc.teragrid";
my $json_text = encode_json \%data;

conga_auth($json_text);

#print("Headers: $headers\n--\n");
#print("Body: ");
#print $body . "\n";
#print Dumper($body) . "\n";
#print Dumper(\$body) . "\n";
#print("\n--\n");

print "end script\n";


## subroutines for sending conga commands ##

# subroutine to authenticate with conga
sub conga_auth
{
	my ($json_str) = @_;

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
	
	print("performing curl request\n");
	 
	# Starts the actual request
	my $retcode = $curl->perform;
	
	print("return code: $retcode\n");
	 
	# Looking at the results
	if ($retcode == 0) {
	        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
	        print("Transfer passed with response code: $response_code\n--\n");
	        # judge result and next action based on $response_code
	        print("Received response: $response_body\n--\n");
	} else {
	        # Error code, type of error, error message
	        print("An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n");
	}
	
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
	my $res_ref = decode_json $data;
	my %res = %$res_ref;
	
	# examine auth response for success code
	if($res{'status'} == 0){
		
	} else {

	}
	print("api_key is: $res{'results'}[0]{'api_key'}\n");	
	${$pointer}=%res;	# copy received data into user-defined pointer

	print Dumper(\%res)."\n";

	#print("pointer value is : $pointer{'api-key'}\n");	

	#save_api_key($res);
	return length($data);
}
