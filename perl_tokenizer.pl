#!/usr/bin/perl

use strict;
use warnings;
use utf8;

open BR, "< Part1Text.txt" or die "can't open input file right now";

while (<BR>) {
  # Only punctuation that is not part of a word is a token on its own.
  # This only works on this text, because one flaw it has is decimal numbers
  # and currency.
  s/([,"$%\^\&*()+=\[\]!?])/ $1 /g;
  s/([^A-Z.])(\.)\s+/$1 $2 /g;
  s/\s+/\n/g;
  print $_;
}
