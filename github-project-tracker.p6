#!/usr/bin/env perl6
use v6;

=begin pod

=head1 NAME

github-project-tracker.p6 authenticate

=end pod

use HTTP::Request;
use HTTP::UserAgent;
use Config::Simple;

# Require SSL
BEGIN {
    if ::('IO::Socket::SSL') ~~ Failure {
        print("1..0 # Skip: IO::Socket::SSL not available\n");
        exit 0;
    }
}

class GithubProjectTracker {
    has $!github_api_uri = "https://api.github.com";
    has @!auth;
    has $!app_name = "github-project-tracking";
    has $!conf_file = "%*ENV<HOME>/.ghptrc";
    
    method request-new-token {

        my $auth_uri = "$!github_api_uri/authorizations";

        my $auth_login = prompt("Please enter your GitHub username? ");
        # this is super hacky... it works for *nix, but we need a better solution
        # noecho user input when entering password
        shell("stty -echo");
        my $auth_password = prompt("Please enter your GitHub password? ");
        # return to echo
        shell("stty echo");

        #my %data = (scopes => "read:org", client_id => "$client_id", client_secret => "$client_secret", note => "$app_name");
        my $request = HTTP::Request.new(POST => URI.new($auth_uri));
        $request.header.field(User-Agent => $!app_name);
        $request.header.field(Accept => 'application/vnd.github.v3+json');
        $request.header.field(
          Authorization => "Basic " ~ MIME::Base64.encode-str("{$auth_login}:{$auth_password}")
        );
        my %data = (scopes => "read:org", note => "$!app_name");
        $request.content = to-json(%data).encode;
        $request.header.field(Content-Length => $request.content.bytes.Str);
        my $ua = HTTP::UserAgent.new;
        $ua.timeout = 10;
        my $auth_response = $ua.request($request);

        my $json-response = from-json($auth_response.content);

        my $conf = Config::Simple.new;
        $conf.filename = $!conf_file;
        $conf<token> = $json-response<token>;
        $conf<hashed_token> = $json-response<hashed_token>;
        $conf<token_last_eight> = $json-response<token_last_eight>;
        $conf<created_at> = $json-response<created_at>;
        $conf<updated_at> = $json-response<updated_at>;
        $conf<scopes> = $json-response<scopes>;
        $conf.write();
  
        return $json-response<token>;
    }

    method get-token {
      if $!conf_file.IO ~~ :e {
        my $conf = Config::Simple.read($!conf_file);
        return $conf<token> ?? $conf<token> !! self.request-new-token;
      } else {
        return self.request-new-token;
      }
    }

    method authenticate {

    }

    submethod BUILD($action = "authenticate", Bool $debug = False) {

    }
}

sub MAIN($action, Bool $debug = False) {
  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  say $gh_tracker.get-token();
}

# Authenticate user and return Oauth token for future use
#my $auth_response = $ua.get($github_api_uri);

#my $auth_response = $ua.post(URI.new($auth_uri), %data);

#if $auth_response.is-success {
#} else {
#    die $auth_response.status-line;
#}
