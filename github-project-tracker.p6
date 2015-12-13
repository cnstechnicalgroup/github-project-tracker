#!/usr/bin/env perl6
use v6;

=begin pod

=head1 NAME

github-project-tracker.p6 authenticate

=end pod

use Config::Simple;
use GitHub::OAuth;

class GithubProjectTracker {
    
    has $!conf_file = "%*ENV<HOME>/.ghptrc";

    method authenticate {

        my $auth_login = prompt("Please enter your GitHub username? ");
        # this is super hacky... it works for *nix, but we need a better solution
        # noecho user input when entering password
        shell("stty -echo");
        my $auth_password = prompt("Please enter your GitHub password? ");
        # return to echo
        shell("stty echo");

        my $gh = GitHub::OAuth.new(
            auth_login => $auth_login,
            auth_password => $auth_password
        );

        my $ghres = $gh.request-new-token(data => {
          :scopes(['user', 'repo', 'gist']),
          :note<test-github-oauth-client>
        });

        my $conf = Config::Simple.new;
        $conf.filename = $!conf_file;
        $conf<token> = $ghres<token>;
        $conf<hashed_token> = $ghres<hashed_token>;
        $conf<token_last_eight> = $ghres<token_last_eight>;
        $conf<created_at> = $ghres<created_at>;
        $conf<updated_at> = $ghres<updated_at>;
        $conf<scopes> = $ghres<scopes>;
        $conf.write();
  
        return $conf<token>;
    }

    method get-token {
      if $!conf_file.IO ~~ :e {
        my $conf = Config::Simple.read($!conf_file);
        return $conf<token> ?? $conf<token> !! self.authenticate;
      } else {
        return self.authenticate;
      }
    }

    submethod BUILD($action = "authenticate", Bool $debug = False) {

    }
}

sub MAIN($action, Bool $debug = False) {
  my $gh_tracker = GithubProjectTracker.new(action => $action, debug => False);
  say $gh_tracker.get-token();
}
