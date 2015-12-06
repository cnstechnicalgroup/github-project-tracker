#!/usr/bin/env perl6
use v6;

use HTTP::UserAgent;
BEGIN {
    if ::('IO::Socket::SSL') ~~ Failure {
        print("1..0 # Skip: IO::Socket::SSL not available\n");
        exit 0;
    }
}

my $client_id = "57c0ac5f51981c04a979";
my $username = prompt("Please enter your GitHub username? ");
my $password = prompt("Please enter your GitHub password? ");
my $github_api_uri = "https://api.github.com";
my $auth_uri = "$github_api_uri/authorizations";
my $uri = "$github_api_uri/authorizations?scopes=read:org&client_id=$client_id";
my $app_name = "github-project-tracking";

my %data = (scopes => "read:org", client_id => "$client_id", note => "$app_name");

my $ua = HTTP::UserAgent.new(useragent => "GitHub Project Tracker");

$ua.auth($username, "$password");

$ua.timeout = 10;

my $response = $ua.get($uri);
#my $response = $ua.get(URI.new($auth_uri), %data);

if $response.is-success {
    say $response; #.content;
} else {
    die $response.status-line;
}
