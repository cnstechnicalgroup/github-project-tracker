#!/usr/bin/env perl6
use v6;

=begin pod

=head1 NAME

github-project-tracker.p6 authenticate

=end pod

use JSON::Pretty;
use GitHub;

class GithubProjectTracker {
    
    has $!conf_file = "%*ENV<HOME>/.ghpt";
		has $!client_id = 'test-github-oauth-client';

    method authenticate {

        my $auth_login = prompt("Please enter your GitHub username? ");
        # this is super hacky... it works for *nix, but we need a better solution
        # noecho user input when entering password
        shell("stty -echo");
        my $auth_password = prompt("Please enter your GitHub password? ");
        # return to echo
        shell("stty echo");

        my $gh = GitHub.new(
            auth_login => $auth_login,
            auth_password => $auth_password
        );

        my $ghres = $gh.create_authorization(data => {
          :scopes(['user', 'repo', 'gist']),
          :note<test-github-oauth-client>
        });

				# Prepare new config file
        my %conf = [
						username => $auth_login,
						token => $ghres<token>,
						fingerprint => $ghres<fingerprint>,
						hashed_token => $ghres<hashed_token>,
						token_last_eight => $ghres<token_last_eight>,
						created_at => $ghres<created_at>,
						updated_at => $ghres<updated_at>,
						scopes => $ghres<scopes>
				];

        my $fh = open $!conf_file, :w;
        $fh.print(to-json(%conf));
        $fh.print("\n");
        $fh.close();
        return %conf<token>;
    }

    method get-token {
      if $!conf_file.IO ~~ :e {
        my %conf = from-json(slurp($!conf_file));
        return %conf<token> ?? %conf<token> !! self.authenticate;
      } else {
        return self.authenticate;
      }
    }

    method reset-token {

  	    my %conf = from-json(slurp($!conf_file));
				%conf<fingerprint> !~~ "" or return;

	      my $gh = GitHub.new(
  	        fingerprint => %conf<fingerprint>
	      );

        my $ghres = $gh.reset_authorization(data => {
          :scopes(['user', 'repo', 'gist']),
          :note<test-github-oauth-client>,
          :fingerprint(%conf<fingerprint>)
        });

  			# Prepare new config file
	      my %newconf = [
					username => %conf<username>,
					token => $ghres<token>,
					fingerprint => $ghres<fingerprint>,
					hashed_token => $ghres<hashed_token>,
					token_last_eight => $ghres<token_last_eight>,
					created_at => $ghres<created_at>,
					updated_at => $ghres<updated_at>,
					scopes => $ghres<scopes>
	  		];

        my $fh = open $!conf_file, :w;
        $fh.print(to-json(%newconf));
        $fh.print("\n");
        $fh.close();
        return %conf<token>;
    }

    method list-authorizations {

  	    my %conf = from-json(slurp($!conf_file));
				%conf<fingerprint> !~~ "" or return;

	      my $gh = GitHub.new(
  	        fingerprint => %conf<token>
	      );

        my $ghres = $gh.list_authorizations(data => {
          :fingerprint(%conf<fingerprint>)
        });

        return $ghres;
    }

    method list-issues (Str $repo) {

  	    my %conf = from-json(slurp($!conf_file));
				%conf<token> !~~ "" or return;

	      my $gh = GitHub.new(
  	        fingerprint => %conf<token>
	      );

        my $ghres = $gh.list_issues(
					repo => $repo,
					data => {
          	:fingerprint(%conf<fingerprint>)
	      	}
				);

        return $ghres;
    }
}

sub MAIN($action, $repo, Bool $debug = False) {
  if $action ~~ 'authenticate' {
	  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  	say $gh_tracker.get-token();
  } elsif $action ~~ 'reset-token' {
	  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  	say $gh_tracker.reset-token();
  } elsif $action ~~ 'list-authorizations' {
	  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  	say $gh_tracker.list-authorizations();
  } elsif $action ~~ 'list-issues' {
	  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  	say $gh_tracker.list-issues($repo);
	}
}
