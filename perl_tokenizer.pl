#!/usr/bin/perl

use strict;
use warnings;
use utf8; # tells perl that this code is encoded in utf8.
binmode STDOUT, ":utf8"; # all standard output from code should be encoded to utf8
use open IN => ":encoding(utf8)", OUT => ":utf8"; #R reading and writing to files in utf8

open BR, "< Part1Text.txt" or die "can't open input file right now";

while (<BR>) {
  # Only punctuation that is not part of a word is a token on its own.
  # In order for it to keep currency tokens, the \p{Sc} was used. It is
  # a property of all currency symbols, that can be used in regexes.
  # source:
  # https://stackoverflow.com/questions/4180316/how-do-i-recognise-currency-symbols-in-perl
  s/(["\p{Sc}%\^\&*()+=\[\]!?])/ $1 /g;
  s/([^A-Z.\p{Sc}])([.,])\s+/$1 $2 /g;
  s/\s+/\n/g;
  print $_;
}
