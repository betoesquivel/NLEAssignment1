#!/usr/bin/env perl

use strict;
use warnings;
use utf8; # tells perl that this code is encoded in utf8.
binmode STDOUT, ":utf8"; # all standard output from code should be encoded to utf8
use open IN => ":encoding(utf8)", OUT => ":utf8"; # reading and writing to files in utf8

use HTML::TreeBuilder::XPath;

sub get_stations
{
  # I can scrape the information from "http://www.abelliogreateranglia.co.uk/travel-information/station-information";

  # 2) Get decoded content of webpage
  open BR, "< stations.html" or die "Couldn't open timetable file";
  my $timetables_webpage = join("", <BR>);

  # 3) Extract story out of webpage
  my $tree = HTML::TreeBuilder::XPath->new();
  $tree->parse($timetables_webpage);
  my $stations_xpath = '/html/body/div[3]/div/div[1]/div/div[2]';

  return $tree->findvalue($stations_xpath);
}

# Receives an array with which to build a regex using alternation.
sub build_regex_from_array
{
  my $alternated_stations = join('|', @_);
  return qr/($alternated_stations)/
}

sub chat
{
  my $re_weekday     = qr/(?<weekday>tuesday|monday|wednesday|thursday|friday|saturday|sunday)/i;
  my $re_clocktime   = qr/(?<clocktime>\d{1,2}(:\d{2})?\s*?(pm|am))/i;

  my $re_dayno       = qr/(?<dayno>\d{1,2})/;
  my $re_day         = qr/(?<day>$re_dayno|tomorrow|next week|the\sday\safter\stomorrow|(next)?\s$re_weekday)/;
  my $re_month       = qr/(?<month>january|february|march|april|may|june|july|august|september|october|november|december)/i;
  my $re_year        = qr/(?<year>\d{4})/;
  my $re_time_in_the = qr/(?<t_in_the>morning|afternoon|evening)/i;
  my $re_time        = qr/(?<t>any\s?time|tonight)/i;
  my $re_time_at     = qr/(?<t_at>night|$re_clocktime)/i;
  my $re_stations    = $_[0]; #contains all stations extracted from a file with the website

  my $re_terminators = qr/(good bye|thank you|bye|bye bye)/i;
  my $re_positive = qr/(yes|yeah|please|yup|aha|correct|right)/i;
  my $re_negative = qr/(no|nope|nop|nah|wrong|incorrect)/i;


  print "Hi, my name is Eliza, your personal Greater Anglia travel assistant.\n";
  print "With what can I help you with?\n";

  my $p_destination;
  my $p_time;
  my $p_day;

  my $destination = '';
  my $time = '';
  my $day = '';
  while (<STDIN>) {
    # check for places in input
    if (/$re_stations/) {
      $destination = $1;
      print "Found destination: $destination\n";
    }
    # check for timing information in input
    if (/($re_time_in_the|$re_time|$re_time_at)/){
      $time = " in the $+{t_in_the}" if defined $+{t_in_the};
      $time = " $+{t}"               if defined $+{t};
      $time = " at $+{t_at}"         if defined $+{t_at};
    }
    # check for day information in input
    if (/$re_day/){
      $day = " $+{day}";
      $day .= " on the $+{dayno}" if defined $+{dayno};
    }
    if (/$re_month/){
      $day =~ s/$re_dayno/ on the $+{dayno} $+{month}/;
    }
    if (/$re_year/){
      $day =~ s/.*($re_dayno|$re_month|$re_dayno\s$re_month)/on the $+{dayno} $+{month}, $+{year}/;
    }

    if ($destination =~ /.+/) {
      print "Do you want me to check availability for tickets to $destination$day$time?\n";
      if (<STDIN>=~$re_positive) {
        print "I am sorry but unfortunately there are no tickets available due to weather conditions.\n";
      }else {
        print "I am sorry to hear that.\n";
      }
      print "Is there anything else I can help you with?\n";
      if (<STDIN>=~$re_negative) {
        print "Ok, thank you for choosing Greater Anglia travel.\n";
        print "Good bye\n";
        exit;
      }else {
        $destination = '';
        $day = '';
        $time = '';
      }
    }else {
      print "I am here to help you only with your train tickets booking, please give me a destination.\n";
    }
    if (/$re_terminators/){
      print "Thank you for choosing Greater Anglia travel.\n";
      exit;
    }

    # Check if I have enough information to book a ticket
    # If I do, randomize offer to book or unfortunate
    # Wait for response if offer to book
    # Anything else
    # exit if no
  }
}

my $stations_txt = get_stations;
$stations_txt =~ s/\(.*?\)//g;
$stations_txt =~ s/\s+/|/g;
chop($stations_txt);
my $re_stations = qr/($stations_txt)/i;
chat($re_stations);
