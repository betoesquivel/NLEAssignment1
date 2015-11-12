#!/usr/bin/env perl
# The following script requires LWP::Simple and HTML::TreeBuilder::XPath
# for the web scraping of the bbc websites.
# If you don't want to install them, you can just remove the parts
# that have to deal with the scraping, and the code will end up being
# just the parse_file_drectly, build_regex, and extract_currency functions.
# Also, the commandline options would have to be removed, so that it always
# parsed the file directly.
use strict;
use warnings;
use utf8;
use charnames qw[ :full ];
binmode STDOUT, ":utf8";
use open IN => ":encoding(utf8)", OUT => ":utf8";

use LWP::Simple;
use HTML::TreeBuilder::XPath;
our $xml;

sub scrape_bbc_for_story
{
  my $URL = "http://www.bbc.co.uk/news/business-34664777";
  #my $URL = "http://www.bbc.co.uk/news/business-34707288";

  # 1) Prepare scraper
  my $UserAgent = new LWP::UserAgent;

  # 2) Get decoded content of webpage
  my $request = new HTTP::Request('get', $URL);
  my $response = $UserAgent->request($request);
  my $bbc_webpage = $response->decoded_content();

  # 3) Extract story out of webpage
  my $tree = HTML::TreeBuilder::XPath->new();
  $tree->parse($bbc_webpage);
  my $story_xpath = '//*[@id="page"]/div/div[2]/div/div[1]/div[1]';

  return $tree->findvalue($story_xpath);
}

# Receives the file name as a parameter, and returns the contents in a string.
sub parse_file_directly
{
  open BR, "< $_[0]" or die "Couldn't open file right now.";
  while (<BR>) {
    extract_currency($_);
  }
}

# 4) Build regular expression
# Returns a regular expression that can id currency (pounds, dollars, kroner)
sub build_regex
{
  # 4.1 Named groups when a Symbol is matched
  my $Symbol = qr/(?<symbol>\p{Sc})/;
  my $S_amount = qr/(?<s_amount>(\d+|\d{1,3},\d{3})(\.\d+)?)/;
  my $S_m_bn = qr/(?<s_m_bn>(m|bn))/;
  my $S_currency = qr/(?<s_currency>(euros?|pounds|dollars|kroner))/;

  my $re_currency_w_symbol = qr/${Symbol}${S_amount}${S_m_bn}?(\s${S_currency})?/;

  # 4.2 Named groups when a Symbol is not matched
  my $amount = qr/(?<amount>(\d+|\d{1,3},\d{3})(\.\d+)?)/;
  my $m_bn = qr/(?<m_bn>(m|bn))/;
  my $currency = qr/(?<currency>(\seuros?|\spounds|\sdollars|\skroner|p))/;

  my $re_currency_wo_symbol = qr/${amount}${m_bn}?${currency}/;

  # 4.3 Final regular expression
  return qr/($re_currency_w_symbol|$re_currency_wo_symbol)/;
}

# 5) Find matches
# Receives a string and prints all currency data found there
sub extract_currency
{
  my $regex = build_regex;

  my $EURO_SIGN = "\N{EURO SIGN}";
  my $POUND_SIGN = "\N{POUND SIGN}";
  my $DOLLAR_SIGN = "\N{DOLLAR SIGN}";

  my $symbol, my $money, my $modifier, my $found_currency;
  my $determined_currency;

  my $line = $_[0];
  while ($line =~ /$regex/g) {
    $symbol          = $+{symbol};
    $money           = $+{s_amount}   // $+{amount};
    $modifier        = $+{s_m_bn}     // $+{m_bn};
    $found_currency  = $+{s_currency} // $+{currency};


    if ( defined $symbol ) {
      if ( $symbol =~ /$POUND_SIGN/ ) {
        $determined_currency = "pounds";
      } elsif ( $symbol =~ /$EURO_SIGN/ ) {
        $determined_currency = "euros";
      } elsif ( $symbol =~ /$DOLLAR_SIGN/ ) {
        $determined_currency = "dollars";
      }
    }elsif ( $found_currency =~ /p/ ){
      $determined_currency = "points";
    }

    if ( not defined $determined_currency ) {
      $determined_currency = $found_currency;
    }

    $symbol = $symbol // '';
    $money = $money // '';
    $modifier = $modifier // '';
    $determined_currency = $determined_currency // '';

    if (defined $xml){
      print_currency_as_xml($determined_currency, $money, $modifier);
    }else {
      print_unformatted_currency($determined_currency, $symbol,
                                 $money, $modifier);
    }
    print "\n";
    undef $determined_currency;
    undef $symbol;
    undef $modifier;
  }
}

# Receives Currency name, symbol, amount, and mn or bn
# to output an unformatted version of the currency.
sub print_unformatted_currency
{
    print "Found a match!\n";
    print "Currency: $_[0]\n";
    print "Amount: $_[1]$_[2]$_[3]\n";
}

# Receives Currency name, amount, and mn or bn
# to output an xml version of the currency.
sub print_currency_as_xml
{
print
"<PRICE>
<CURRENCY>$_[0]</CURRENCY>
<AMOUNT>$_[1]$_[2]</AMOUNT>
</PRICE>\n";
}

# MAIN THREAD
print "======================== CURRENCY PARSER =========================\n";
print "Welcome to the currency parser!\n";
print "Send a file as a parameter or allow me to scrape a bbc website.\n";
print "Send -xml as a parameter at the end, if you want the output as xml.\n";
print "Usage: perl currency_transducer.pl <OPTIONAL_FILE_TO_PARSE> -xml\n\n";

if (defined $ARGV[0]) {
  if ($ARGV[0] =~ /-xml/){
    $xml = 1;
    if (defined $ARGV[1]) {
      print "Reading sample text from file $ARGV[1].\n";
      parse_file_directly($ARGV[1]);
      exit;
    }
  } else {
    $xml = 1 if defined $ARGV[1];
    print "Reading sample text from file $ARGV[0].\n";
    parse_file_directly($ARGV[0]);
    exit;
  }
}

# Only in case there was no file in the arguments.
print "Scraping sample text from UK website.\n";
my $story = scrape_bbc_for_story;
extract_currency($story);
