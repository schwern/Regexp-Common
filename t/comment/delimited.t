#!/usr/bin/perl

use strict;
use vars qw /$VERSION/;
use lib "blib/lib";

use Regexp::Common qw /RE_comment_ALL/;
use t::Common qw /run_new_tests/;

use warnings;

($VERSION) = q $Revision: 2.103 $ =~ /[\d.]+/;

BEGIN {$^W = 0 if $] < 5.006}

my @delimited = do {
    no warnings;
    (   [qw {comment  ;} => ['Algol 60']],
        [qw {/*      */} => [qw {ALPACA B C C-- LPC PL/I}]],
        [qw {;        ;} => [qw {Befunge-98 Funge-98 Shelta}]],
        [qw {<?_c  _c?>} => [qw {BML}]],
        [qw !{        }! => [qw {False}]],
        [qw {,        ,} => [qw {Haifu}]],
        [qw {(*      *)} => [qw {Oberon}]],
        [qw {"        "} => [qw {Smalltalk}]],
        [qw {||      !!} => [qw {*W}]],
    )
};


#
# Some basic comments, not including delimiters.
#
my @comments = ("", "This is a comment", "This is a\nmultiline comment",
                "\n", "*", "\n*\n", "/*", "(*", "||", "{");

# Targets, and test suites.
my %targets;
my @tests;

foreach my $entry (@delimited) {
    my ($start, $end) = @$entry [0, 1];
    my  $langs        = $$entry [2];
    my $pass_key      = "pass_${start}_${end}";
    my $fail_key      = "fail_${start}_${end}";

    $targets {$pass_key} = {
        list     => \@comments,
        query    => sub {$start . $_ [0] . $end},
        wanted   => sub {$_, $start, $_ [0], $end},
    };

    # Create bad comments.
    my @bad_comments;
    # No terminating token.
    # Not for pre 5.006 perls due to tests taking too much time.
    push @bad_comments => map {"$start$_"} @comments if $] >= 5.006;
    # No starting token.
    push @bad_comments => map {"$_$end"} grep {index ($_, $start)} @comments;
    # Double terminators.
    push @bad_comments => map {"$start$_$end$end"} @comments;
    # Double the comment.
    push @bad_comments => map {"$start$_$end" x 2} @comments;
    # Different token.
    my @bad_tokens = grep {index $_ -> [0], $start} @delimited;
    push @bad_comments => map {my $c = $_;
                               map {$_ -> [0] . $c . $_ -> [1]} @bad_tokens
                          } @comments;
    # No tokens.
    push @bad_comments => @comments;
    # Text preceeding comment.
    push @bad_comments => map {"Text $start$_$end"} @comments;
    # Some more.
    push @bad_comments => "<!-- This is an HTML  comment -->";
    push @bad_comments => "/*   This is a C      comment */" if $start ne '/*';
    push @bad_comments => "{    This is a Pascal comment }"  if $start ne '{';

    $targets {$fail_key} = {
        list     => \@bad_comments,
    };

    foreach my $lang (@$langs) {
        my $langX = $lang;
        $langX =~ s/\W/X/g;
        no strict 'refs';
        push @tests => {
            name    => $lang,
            regex   => $RE {comment} {$lang},
            sub     => \&{"RE_comment_$langX"},
            pass    => [$pass_key],
            fail    => [$fail_key],
        }
    }
}

run_new_tests tests        => \@tests,
              targets      => \%targets,
              version_from => 'Regexp::Common::comment',


__END__

 $Log: delimited.t,v $
 Revision 2.103  2008/05/26 17:05:17  abigail
 use warnings

 Revision 2.102  2005/01/09 23:12:27  abigail
 BML comments

 Revision 2.101  2005/01/01 16:41:10  abigail
 Renamed 'version' argument of 'run_new_tests' to 'version_from'

 Revision 2.100  2004/12/28 23:01:05  abigail
 Moved tests out of t/test_comment.t

