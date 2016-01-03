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
						token => $ghres<token>,
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
}

sub MAIN($action, Bool $debug = False) {
  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  say $gh_tracker.get-token();
}
