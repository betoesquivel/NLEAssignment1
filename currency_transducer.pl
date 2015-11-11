use strict;
use warnings;
use utf8;
use charnames qw[ :full ];
binmode STDOUT, ":utf8";

use LWP::Simple;
use HTML::TreeBuilder::XPath;

# 1) Prepare scraper
# my $URL = "http://www.bbc.co.uk/news/business-34664777";
my $URL = "http://www.bbc.co.uk/news/business-34707288";

my $UserAgent = new LWP::UserAgent;

# 2) Get decoded content of webpage
my $request = new HTTP::Request('get', $URL);
my $response = $UserAgent->request($request);
my $bbc_webpage = $response->decoded_content();

# 3) Extract story out of webpage
my $tree = HTML::TreeBuilder::XPath->new();
$tree->parse($bbc_webpage);
my $story_xpath = '//*[@id="page"]/div/div[2]/div/div[1]/div[1]';
my $story = $tree->findvalue($story_xpath);

# 4) Build regular expression
# 4.1 Named groups when a Symbol is matched
my $Symbol = qr/(?<symbol>\p{Sc})/;
my $S_amount = qr/(?<s_amount>(\d+|\d{1,3},\d{3})(\.\d+)?)/;
my $S_m_bn_p = qr/(?<s_m_bn_p>(m|bn|p))/;
my $S_currency = qr/(?<s_currency>(euros?|pounds|dollars|kroner))/;

my $re_currency_w_symbol = qr/${Symbol}${S_amount}${S_m_bn_p}?(\s${S_currency})?/;

# 4.2 Named groups when a Symbol is not matched
my $amount = qr/(?<amount>(\d+|\d{1,3},\d{3})(\.\d+)?)/;
my $m_bn_p = qr/(?<m_bn_p>(m|bn|p))/;
my $currency = qr/(?<currency>(euros?|pounds|dollars|kroner))/;

my $re_currency_wo_symbol = qr/${amount}${m_bn_p}?\s${currency}/;

# 4.3 Capture points... $Amount+p

# 4.4 Final regular expression
my $regex = qr/($re_currency_w_symbol|$re_currency_wo_symbol)/;

# 5) Find matches
my $EURO_SIGN = "\N{EURO SIGN}";
my $POUND_SIGN = "\N{POUND SIGN}";
my $DOLLAR_SIGN = "\N{DOLLAR SIGN}";

my $symbol, my $money, my $modifier, my $found_currency;
my $determined_currency;
while ($story =~ /$regex/g) {
  $symbol          = $+{symbol};
  $money           = $+{s_amount}   // $+{amount};
  $modifier        = $+{s_m_bn_p}   // $+{m_bn_p};
  $found_currency  = $+{s_currency} // $+{currency};

  $determined_currency = $found_currency // $determined_currency;

  if ( not defined $determined_currency ) {

    if ( defined $symbol ) {
      if ( $symbol =~ $POUND_SIGN ) {
        $determined_currency = "pounds";
      } elsif ( $symbol =~ /$EURO_SIGN/ ) {
        $determined_currency = "euros";
      } elsif ( $symbol =~ /$DOLLAR_SIGN/ ) {
        $determined_currency = "dollars";
      }
    }

    if ( defined $modifier ) {
      if ( $modifier =~ /p/ ) {
        $determined_currency = "pounds";
      }
    }

  }

  $symbol = $symbol // '';
  $money = $money // '';
  $modifier = $modifier // '';
  $determined_currency = $determined_currency // '';
  print "$symbol$money$modifier $determined_currency\n";
}
