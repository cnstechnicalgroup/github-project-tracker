#!/usr/bin/env perl6
use v6;

use HTTP::Request;
use HTTP::UserAgent;

# Require SSL
BEGIN {
    if ::('IO::Socket::SSL') ~~ Failure {
        print("1..0 # Skip: IO::Socket::SSL not available\n");
        exit 0;
    }
}

# GitHub app details
my $app_name = "github-project-tracking";
# GitHup API URI
my $github_api_uri = "https://api.github.com";
# GitHub Authorization endpoint
my $auth_uri = "$github_api_uri/authorizations";

my $auth_login = prompt("Please enter your GitHub username? ");
my $auth_password = prompt("Please enter your GitHub password? ");

#my %data = (scopes => "read:org", client_id => "$client_id", client_secret => "$client_secret", note => "$app_name");
my $request = HTTP::Request.new(POST => URI.new($auth_uri));
$request.header.field(User-Agent => $app_name);
$request.header.field(Accept => 'application/vnd.github.v3+json');
$request.header.field(
  Authorization => "Basic " ~ MIME::Base64.encode-str("{$auth_login}:{$auth_password}")
);
my %data = (scopes => "read:org", note => "$app_name");
$request.content = to-json(%data).encode;
$request.header.field(Content-Length => $request.content.bytes.Str);
my $ua = HTTP::UserAgent.new;
$ua.timeout = 10;
my $auth_response = $ua.request($request);

# Authenticate user and return Oauth token for future use
#my $auth_response = $ua.get($github_api_uri);

#my $auth_response = $ua.post(URI.new($auth_uri), %data);

#if $auth_response.is-success {
    say "$auth_response"; #.content;
    say to-json(%data);
#} else {
#    die $auth_response.status-line;
#}
