use strict;
use Irssi 20020101.0250 (***REMOVED***
use vars qw($VERSION %IRSSI***REMOVED*** 
$VERSION = "1";
%IRSSI = (
    authors     => "Timo Sirainen, Ian Peters",
    contact => "tss\@iki.fi", 
    name        => "Nick Color",
    description => "assign a different color for each nick",
    license => "Public Domain",
    url     => "http://irssi.org/",
    changed => "2002-03-04T22:47+0100"
***REMOVED***

# hm.. i should make it possible to use the existing one..
Irssi::theme_register([
  'pubmsg_hilight', '{pubmsghinick $0 $3 $1}$2'
]***REMOVED***

my %saved_colors;
my %session_colors = {***REMOVED***
my @colors = qw/ 2 3 4 5 6 7 9 10 11 12 13 14 15/;

sub load_colors {
  open COLORS, "$ENV{HOME}/.irssi/saved_colors";

  while (<COLORS>) {
    # I don't know why this is necessary only inside of irssi
    my @lines = split "\n";
    foreach my $line (@lines) {
      my($nick, $color) = split ":", $line;
      $saved_colors{$nick} = $color;
  ***REMOVED***
***REMOVED***

  close COLORS;
}

sub save_colors {
  open COLORS, ">$ENV{HOME}/.irssi/saved_colors";

  foreach my $nick (keys %saved_colors) {
    print COLORS "$nick:$saved_colors{$nick}\n";
***REMOVED***

  close COLORS;
}

# If someone we've colored (either through the saved colors, or the hash
# function) changes their nick, we'd like to keep the same color
# associated
# with them (but only in the session_colors, ie a temporary mapping).

sub sig_nick {
  my ($server, $newnick, $nick, $address) = @_;
  my $color;

  $newnick = substr ($newnick, 1) if ($newnick =~ /^:/***REMOVED***

  if ($color = $saved_colors{$nick}) {
    $session_colors{$newnick} = $color;
***REMOVED*** elsif ($color = $session_colors{$nick}) {
    $session_colors{$newnick} = $color;
***REMOVED***
}

# This gave reasonable distribution values when run across
# /usr/share/dict/words

sub simple_hash {
  my ($string) = @_;
  chomp $string;
  my @chars = split //, $string;
  my $counter;

  foreach my $char (@chars) {
    $counter += ord $char;
***REMOVED***

  $counter = $colors[$counter % 11];

  return $counter;
}

# FIXME: breaks /HILIGHT etc.
sub sig_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  my $chanrec = $server->channel_find($target***REMOVED***
  return if not $chanrec;
  my $nickrec = $chanrec->nick_find($nick***REMOVED***
  return if not $nickrec;
  my $nickmode = $nickrec->{op} ? "@" : $nickrec->{voice} ? "+" : "";

  # Has the user assigned this nick a color?
  my $color = $saved_colors{$nick***REMOVED***

  # Have -we- already assigned this nick a color?
  if (!$color) {
    $color = $session_colors{$nick***REMOVED***
***REMOVED***

  # Let's assign this nick a color
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
***REMOVED***

  $color = "0".$color if ($color < 10***REMOVED***
  $server->command('/^format pubmsg %b<%w$2'.chr(3).$color.'$[-11]0%b>
%K|%n $1'***REMOVED***
 # $server->command('/^format action_public {pubaction
 # '.chr(3).$color.'$0}$1'***REMOVED***
}

sub cmd_color {
  my ($data, $server, $witem) = @_;
  my ($op, $nick, $color) = split " ", $data;

  $op = lc $op;

  if (!$op) {
    Irssi::print ("No operation given"***REMOVED***
***REMOVED*** elsif ($op eq "save") {
    save_colors;
***REMOVED*** elsif ($op eq "set") {
    if (!$nick) {
      Irssi::print ("Nick not given"***REMOVED***
  ***REMOVED*** elsif (!$color) {
      Irssi::print ("Color not given"***REMOVED***
  ***REMOVED*** elsif ($color < 2 || $color > 14) {
      Irssi::print ("Color must be between 2 and 14 inclusive"***REMOVED***
  ***REMOVED*** else {
      $saved_colors{$nick} = $color;
  ***REMOVED***
***REMOVED*** elsif ($op eq "clear") {
    if (!$nick) {
      Irssi::print ("Nick not given"***REMOVED***
  ***REMOVED*** else {
      delete ($saved_colors{$nick}***REMOVED***
  ***REMOVED***
***REMOVED*** elsif ($op eq "list") {
    Irssi::print ("\nSaved Colors:"***REMOVED***
    foreach my $nick (keys %saved_colors) {
      Irssi::print (chr (3) . "$saved_colors{$nick}$nick" .
          chr (3) . "1 ($saved_colors{$nick})"***REMOVED***
  ***REMOVED***
***REMOVED*** elsif ($op eq "preview") {
    Irssi::print ("\nAvailable colors:"***REMOVED***
    foreach my $i (2..14) {
      Irssi::print (chr (3) . "$i" . "Color #$i"***REMOVED***
  ***REMOVED***
***REMOVED***
}

load_colors;

Irssi::command_bind('color', 'cmd_color'***REMOVED***

Irssi::signal_add('message public', 'sig_public'***REMOVED***
Irssi::signal_add('event nick', 'sig_nick'***REMOVED***
