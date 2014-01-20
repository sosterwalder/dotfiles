use strict;
use Irssi (***REMOVED***
use Irssi::TextUI;
use Encode;

use vars qw($VERSION %IRSSI $BLOCK_ALL***REMOVED***

$VERSION = '0.7e';
%IRSSI = (
	authors          => 'Nei',
	contact          => 'Nei @ anti@conference.jabber.teamidiot.de',
	url              => "http://anti.teamidiot.de/",
	name             => 'awl',
	description      => 'Adds a permanent advanced window list on the right or in a statusbar.',
	license          => 'GNU GPLv2 or later',
***REMOVED***

# Usage
# =====
# copy the script to ~/.irssi/scripts/
#
# In irssi:
#
#		/script load adv_windowlist
#
#
# Hint: to get rid of the old [Act:] display
#     /statusbar window remove act
#
# to get it back:
#     /statusbar window add -after lag -priority 10 act

# Options
# =======
# /set awl_display_(no)key(_active|_visible) <string>
# * string : Format String for one window. The following $'s are expanded:
#     $C : Name
#     $N : Number of the Window
#     $Q : meta-Keymap
#     $H : Start highlighting
#     $S : Stop highlighting
#         /+++++++++++++++++++++++++++++++++,
#        | ****  I M P O R T A N T :  ****  |
#        |                                  |
#        | don't forget  to use  $S  if you |
#        | used $H before!                  |
#        |                                  |
#        '+++++++++++++++++++++++++++++++++/
#
# /set awl_display_header <string>
# * string : Format String for this header line. The following $'s are expanded:
#     $C : network tag
#
# /set awl_separator <string>
# * string : Charater to use between the channel entries
# 	  you'll need to escape " " space and "$" like this:
# 	  "/set awl_separator \ "
# 	  "/set awl_separator \$"
# 	  and {}% like this:
# 	  "/set awl_separator %{"
# 	  "/set awl_separator %}"
# 	  "/set awl_separator %%"
# 	  (reason being, that the separator is used inside a {format })
#
# /set awl_prefer_name <ON|OFF>
# * this setting decides whether awl will use the active_name (OFF) or the
#   window name as the name/caption in awl_display_*.
#   That way you can rename windows using /window name myownname.
#
# /set awl_hide_empty <num>
# * if visible windows without items should be hidden from the window list
# set it to 0 to show all windows
#           1 to hide visible windows without items (negative exempt active window)
#
# /set awl_hide_data <num>
# * num : hide the window if its data_level is below num
# set it to 0 to basically disable this feature,
#           1 if you don't want windows without activity to be shown
#           2 to show only those windows with channel text or hilight
#           3 to show only windows with hilight (negative exempt active window)
#
# /set awl_maxlines <num>
# * num : number of lines to use for the window list (0 to disable, negative
#   lock)
#
# /set awl_columns <num>
# * num : number of columns to use in fifo mode (0 for unlimited)
#
# /set awl_block <num>
# * num : width of a column in fifo mode (negative values = block display)
#         /+++++++++++++++++++++++++++++++++,
#        | ******  W A R N I N G !  ******  |
#        |                                  |
#        | If  your  block  display  looks  |
#        | DISTORTED,  you need to add the  |
#        | following  line to your  .theme  |
#        | file under                       |
#        |     abstracts = {             :  |
#        |                                  |
#        |       sb_act_none = "%n$*";      |
#        |                                  |
#        '+++++++++++++++++++++++++++++++++/
#
#  /set awl_sbar_maxlength <ON|OFF>
#  * if you enable the maxlength setting, the block width will be used as a
#    maximum length for the non-block statusbar mode too.
#
#  /set awl_height_adjust <num>
#  * num : how many lines to leave empty in fifo mode
#
#  /set awl_sort <-data_level|-last_line|refnum>
#  * you can change the window sort order with this variable
#      -data_level : sort windows with hilight first
#      -last_line  : sort windows in order of activity
#      refnum      : sort windows by window number
#
#  /set awl_placement <top|bottom>
#  /set awl_position <num>
#  * these settings correspond to /statusbar because awl will create
#    statusbars for you
#  (see /help statusbar to learn more)
#
#  /set awl_all_disable <ON|OFF>
#  * if you set awl_all_disable to ON, awl will also remove the
#    last statusbar it created if it is empty.
#    As you might guess, this only makes sense with awl_hide_data > 0 ;)

# Commands
# ========
# /awl redraw
#     * redraws the fifo windowlist. There are many occasions where the
#       fifo windowlist can get destroyed so you can use this command to
#       fix it.

# Nei =^.^= ( anti@conference.jabber.teamidiot.de )

use Storable (***REMOVED***
use Fcntl;

my $actString = [];   # statusbar texts
my $currentLines = 0;
my $resetNeeded;      # layout/screen has changed, redo everything
my $needRemake;       # "normal" changes
my %awins;
sub GLOB_QUEUE_TIMER () { 100 }
my $globTime = undef; # timer to limit remake() calls
my $globTime2 = undef;


my $SCREEN_MODE;
my $FIFO_MODE;
my $MOUSE_ON = undef;
my $FIRST_RUN = 1;
my $currentColumns = 0;
my $screenResizing;
my ($screenHeight, $screenWidth***REMOVED***
my $terminfo = bless { # xterm here, make this modular
	NAME => 'Term::Info::xterm',
	PARENTS => [],
	METHODS => {
		civis => sub { "\033[?25l" },
		sc    => sub { "\0337" },
		cup   => sub { shift;shift; "\033[" . ($_[0] + 1) . ';' . ($_[1] + 1) . 'H' },
		el    => sub { "\033[K" },
		rc    => sub { "\0338" },
		cnorm => sub { "\033[?25h" },
		setab => sub { shift;shift; "\033[4" . $_[0] . 'm' },
		setaf => sub { shift;shift; "\033[3" . $_[0] . 'm' },
		setaf16 => sub { shift;shift; "\033[9" . $_[0] . 'm' },
		bold  => sub { "\033[1m" },
		blink => sub { "\033[5m" },
		rev   => sub { "\033[7m" },
		op    => sub { "\033[39;49m" },
	}
}, 'Class::Classless::X';

sub setc () {
	$IRSSI{'name'}
}
sub set ($) {
	setc . '_' . shift
}

my %statusbars;       # currently active statusbars

sub add_statusbar {
	for (@_) {
		# add subs
		for my $l ($_) { {
			no strict 'refs';
			*{set$l} = sub { awl($l, @_) ***REMOVED***
		***REMOVED*** }
		Irssi::command('statusbar ' . (set$_) . ' reset'***REMOVED***
		Irssi::command('statusbar ' . (set$_) . ' enable'***REMOVED***
		if (lc Irssi::settings_get_str(set 'placement') eq 'top') {
			Irssi::command('statusbar ' . (set$_) . ' placement top'***REMOVED***
		}
		if ((my $x = int Irssi::settings_get_int(set 'position')) != 0) {
			Irssi::command('statusbar ' . (set$_) . ' position ' . $x***REMOVED***
		}
		Irssi::command('statusbar ' . (set$_) . ' add -priority 100 -alignment left barstart'***REMOVED***
		Irssi::command('statusbar ' . (set$_) . ' add ' . (set$_)***REMOVED***
		Irssi::command('statusbar ' . (set$_) . ' add -priority 100 -alignment right barend'***REMOVED***
		Irssi::command('statusbar ' . (set$_) . ' disable'***REMOVED***
		Irssi::statusbar_item_register(set$_, '$0', set$_***REMOVED***
		$statusbars{$_} = {***REMOVED***
	}
}

sub remove_statusbar {
	for (@_) {
		Irssi::command('statusbar ' . (set$_) . ' reset'***REMOVED***
		Irssi::statusbar_item_unregister(set$_***REMOVED***
		# DO NOT REMOVE the sub before you have unregistered it :))
		for my $l ($_) { {
			no strict 'refs';
			undef &{set$l***REMOVED***
		***REMOVED*** }
		delete $statusbars{$_***REMOVED***
	}
}

sub syncLines {
	my $temp = $currentLines;
	$currentLines = @$actString;
	my $currMaxLines = Irssi::settings_get_int(set 'maxlines'***REMOVED***
	if ($currMaxLines > 0 and @$actString > $currMaxLines) {
		$currentLines = $currMaxLines;
	}
	elsif ($currMaxLines < 0) {
		$currentLines = abs($currMaxLines***REMOVED***
	}
	return if ($temp == $currentLines***REMOVED***
	if ($currentLines > $temp) {
		for ($temp .. ($currentLines - 1)) {
			add_statusbar($_***REMOVED***
			Irssi::command('statusbar ' . (set$_) . ' enable'***REMOVED***
		}
	}
	else {
		for ($_ = ($temp - 1***REMOVED*** $_ >= $currentLines; $_--) {
			Irssi::command('statusbar ' . (set$_) . ' disable'***REMOVED***
			remove_statusbar($_***REMOVED***
		}
	}
}

sub awl {
	return if $BLOCK_ALL;
	my ($line, $item, $get_size_only) = @_;

	if ($needRemake) {
		$needRemake = undef;
		remake(***REMOVED***
	}

	my $text = $actString->[$line];  # DO NOT set the actual
                                     # $actString->[$line] to '' here
                                     # or
	$text = '' unless defined $text; # you'll screw up the statusbar
                                     # counter ($currentLines)
	$item->default_handler($get_size_only, $text, '', 1***REMOVED***
}

# remove old statusbars
my %killBar;
sub get_old_status {
	my ($textDest, $cont, $cont_stripped) = @_;
	if ($textDest->{'level'} == 524288 and $textDest->{'target'} eq ''
			and !defined($textDest->{'server'})
	) {
		my $name = quotemeta(set ''***REMOVED***
		if ($cont_stripped =~ m/^$name(\d+)\s/) { $killBar{$1} = {***REMOVED*** }
		Irssi::signal_stop(***REMOVED***
	}
}
sub killOldStatus {
	%killBar = (***REMOVED***
	Irssi::signal_add_first('print text' => 'get_old_status'***REMOVED***
	Irssi::command('statusbar'***REMOVED***
	Irssi::signal_remove('print text' => 'get_old_status'***REMOVED***
	remove_statusbar(keys %killBar***REMOVED***
}


my (%keymap, %wnmap***REMOVED***

sub get_keymap {
	my ($textDest, undef, $cont_stripped) = @_;
	if ($textDest->{'level'} == 524288 and $textDest->{'target'} eq ''
			and !defined($textDest->{'server'})
	) {
		if ($cont_stripped =~ m/((?:meta-)*)(meta-|\^)(\S)\s+(.*)$/) {
			my ($level, $ctl, $key, $command) = ($1, $2, $3, $4***REMOVED***
			my $numlevel = ($level =~ y/-//***REMOVED***
			$ctl eq '^' or $ctl = '';
			my $map = ('-' x ($numlevel%2)) . ('+' x ($numlevel/2)) .
																				$ctl . "$key";
			if ($command =~ m/^change_window (\d+)/) {
				my ($window) = ($1***REMOVED***
				$keymap{$window} = $map;
			}
			elsif ($command =~ m/^command window goto (\S+)/i) {
				my ($window) = ($1***REMOVED***
				if ($window !~ /\D/) {
					$keymap{$window} = $map;
				}
				else {
					$wnmap{$window} = $map;
				}
			}
		}
		Irssi::signal_stop(***REMOVED***
	}
}

sub update_keymap {
	%keymap = (***REMOVED***
	Irssi::signal_remove('command bind' => 'watch_keymap'***REMOVED***
	Irssi::signal_add_first('print text' => 'get_keymap'***REMOVED***
	Irssi::command('bind'***REMOVED*** # stolen from grep
	Irssi::signal_remove('print text' => 'get_keymap'***REMOVED***
	Irssi::signal_add('command bind' => 'watch_keymap'***REMOVED***
	Irssi::timeout_add_once(100, 'eventChanged', undef***REMOVED***
}

# watch keymap changes
sub watch_keymap {
	Irssi::timeout_add_once(1000, 'update_keymap', undef***REMOVED***
}

update_keymap(***REMOVED***

sub expand {
	my ($string, %format) = @_;
	my $search = join '|', map { quotemeta } keys %format;
	$string =~ s/\$($search)/$format{$1}/g;
	$string;
}

my %strip_table = (
	# fe-common::core::formats.c:format_expand_styles
	#      delete                format_backs  format_fores bold_fores   other stuff
	(map { $_ => '' } (split //, '04261537' .  'kbgcrmyw' . 'KBGCRMYW' . 'U9_8:|FnN>#[')),
	#      escape
	(map { $_ => $_ } (split //, '{}%')),
***REMOVED***
sub ir_strip_codes { # strip %codes
	my $o = shift;
	$o =~ s/(%(.))/exists $strip_table{$2} ? $strip_table{$2} : $1/gex;
	$o
}

sub ir_parse_special {
	my $o; my $i = shift;
	my $win = shift || Irssi::active_win(***REMOVED***
	my $server = Irssi::active_server(***REMOVED***
	if (ref $win and ref $win->{'active'}) {
		$o = $win->{'active'}->parse_special($i***REMOVED***
	}
	elsif (ref $win and ref $win->{'active_server'}) {
		$o = $win->{'active_server'}->parse_special($i***REMOVED***
	}
	elsif (ref $server) {
		$o =  $server->parse_special($i***REMOVED***
	}
	else {
		$o = Irssi::parse_special($i***REMOVED***
	}
	$o
}
sub ir_parse_special_protected {
	my $o; my $i = shift;
	$i =~ s/
		( \\. ) | # skip over escapes (maybe)
		( \$[^% $\]+ ) # catch special variables
	/
		if ($1) { $1 }
		elsif ($2) { my $i2 = $2; ir_fe(ir_parse_special($i2, @_)) }
		else { $& }
	/gex;
	$i
}


sub sb_ctfe { # Irssi::current_theme->format_expand wrapper
	Irssi::current_theme->format_expand(
		shift,
		(
			Irssi::EXPAND_FLAG_IGNORE_REPLACES
				|
			($_[0]?0:Irssi::EXPAND_FLAG_IGNORE_EMPTY)
		)
	)
}
sub sb_expand { # expand {format }s (and apply parse_special for $vars)
	ir_parse_special(
		sb_ctfe(shift)
	)
}
sub sb_strip {
	ir_strip_codes(
		sb_expand(shift)
	***REMOVED***
}
{
	my $term_type = 'term_type';
	if (Irssi::version > 20040819) { # when did the setting name change?
		$term_type = 'term_charset';
	}
	eval {
		require Text::CharWidth;
	***REMOVED***
	unless ($@) {
		*screen_length = sub {
			Text::CharWidth::mbswidth(+shift)
		***REMOVED***
	}
	else {
		*screen_length = sub {
			my $temp = shift;
			if (lc Irssi::settings_get_str($term_type) eq 'utf-8') {
				Encode::_utf8_on($temp***REMOVED***
			}
			length($temp)
		***REMOVED***
	}
	sub as_uni {
		no warnings 'utf8';
		Encode::decode(Irssi::settings_get_str($term_type), +shift, 0)
	}
	sub as_tc {
		Encode::encode(Irssi::settings_get_str($term_type), +shift, 0)
	}
}
sub sb_length {
	my $temp = sb_strip(shift***REMOVED***
	screen_length($temp)
}

sub ir_escape {
	my $min_level = $_[1] || 0; my $level = $min_level;
	my $o = shift;
	$o =~ s/
		(	%.	)	| # $1
		(	\{	)	| # $2
		(	\}	)	| # $3
		(	\\	)	| # $4
		(	\$(?=[^\\])	)	| # $5
		(	\$	) # $6
	/
		if ($1) { $1 } # %. escape
		elsif ($2) { $level++; $2 } # { nesting start
		elsif ($3) { if ($level > $min_level) { $level--; } $3 } # } nesting end
		elsif ($4) { '\\'x(2**$level) } # \ needs \\escaping
		elsif ($5) { '\\'x(2**$level-1) . '$' . '\\'x(2**$level-1) } # and $ needs even more because of "parse_special"
		else { '\\'x(2**$level-1) . '$' } # $ needs \$ escaping
	/gex;
	$o
}

sub ir_fe { # try to fix format stuff
	my $x = shift;
	$x =~ s/([%{}])/%$1/g;
	$x =~ s/(\\)/\\$1/g;
	$x
}
sub ir_ve { # escapes special vars but leave colours alone
	my $x = shift;
	$x =~ s/(\\|\$|[ ])/\\$1/g;
	$x
}

my %ansi_table;
{
	my ($i, $j, $k) = (0, 0, 0***REMOVED***
	%ansi_table = (
		# fe-common::core::formats.c:format_expand_styles
		#      do                                              format_backs
		(map { $_ => $terminfo->setab($i++) } (split //, '01234567' )),
		#      do                                              format_fores
		(map { $_ => $terminfo->setaf($j++) } (split //, 'krgybmcw' )),
		#      do                                              bold_fores
		(map { $_ => #$terminfo->bold() .
		             $terminfo->setaf16($k++) } (split //, 'KRGYBMCW')),
		# reset
		#(map { $_ => $terminfo->op() } (split //, 'nN')),
		(map { $_ => $terminfo->op() } (split //, 'n')),
		(map { $_ => "\033[0m" } (split //, 'N')), # could be improved
		# flash/bright
		F => $terminfo->blink(),
		# reverse
		8 => $terminfo->rev(),
		# bold
		(map { $_ => $terminfo->bold() } (split //, '9_')),
		#      delete                other stuff
		(map { $_ => '' } (split //, ':|>#[')),
		#      escape
		(map { $_ => $_ } (split //, '{}%')),
	)
}
sub formats_to_ansi_basic {
	my $o = shift;
	$o =~ s/(%(.))/exists $ansi_table{$2} ? $ansi_table{$2} : $1/gex;
	$o
}

sub remove_uniform {
	my $o = shift;
	$o =~ s/^xmpp:(.*?[%@]).+\.[^.]+$/$1/ or
	$o =~ s#^psyc://.+\.[^.]+/([@~].*)$#$1#;
	$o;
}

sub lc1459 ($) { my $x = shift; $x =~ y/A-Z][\^/a-z}{|~/; $x }
Irssi::settings_add_str(setc, 'banned_channels', ''***REMOVED***
Irssi::settings_add_bool(setc, 'banned_channels_on', 0***REMOVED***
my %banned_channels = map { lc1459($_) => undef }
split ' ', Irssi::settings_get_str('banned_channels'***REMOVED***
Irssi::settings_add_str(setc, 'fancy_abbrev', 'fancy'***REMOVED***

sub remake () {
	return if $BLOCK_ALL; # cannot remake during visible window detection
	my ($hilight, $number, $display***REMOVED***
	my $separator = '{sb_act_sep ' . Irssi::settings_get_str(set 'separator') .
		'}';
	my $custSort = Irssi::settings_get_str(set 'sort'***REMOVED***
	my $custSortDir = 1;
	if ($custSort =~ /^[-!](.*)/) {
		$custSortDir = -1;
		$custSort = $1;
	}

	my @wins =
		sort {
			(
				( (int($a->{$custSort}) <=> int($b->{$custSort})) * $custSortDir )
					||
				($a->{'refnum'} <=> $b->{'refnum'})
			)
		} Irssi::windows;
	my $block = Irssi::settings_get_int(set 'block'***REMOVED***
	my $columns = $currentColumns;
	my $oldActString = $actString if $SCREEN_MODE;
	$actString = $SCREEN_MODE ? ['   A W L'] : [];
	my $line = $SCREEN_MODE ? 1 : 0;
	my $width = $FIFO_MODE ? 0 :
		($SCREEN_MODE ? $screenWidth - abs($block)*$columns + 1 :
		([Irssi::windows]->[0]{'width'} - sb_length('{sb x}'))***REMOVED***
	my $height = $screenHeight - (Irssi::settings_get_int(set
			'height_adjust')***REMOVED***
	my ($numPad, $keyPad) = (0, 0***REMOVED***
	my %abbrevList;
	if ($SCREEN_MODE or Irssi::settings_get_bool(set 'sbar_maxlength')
			or ($block < 0)
	) {
		%abbrevList = (***REMOVED***
		if (Irssi::settings_get_str('fancy_abbrev') !~ /^(no|off|head)/i) {
			my @nameList = map { as_uni($_) }
				map { ref $_ ? remove_uniform($_->get_active_name) : '' } @wins;
			for (my $i = 0; $i < @nameList - 1; ++$i) {
				my ($x, $y) = ($nameList[$i], $nameList[$i + 1]***REMOVED***
				for ($x, $y) { s/^[+#!=]// }
				my $res = Algorithm::LCSS::LCSS($x, $y***REMOVED***
				if (defined $res) {
					$abbrevList{$nameList[$i]} = int (index($nameList[$i], $res) +
						(length($res) / 2)***REMOVED***
					$abbrevList{$nameList[$i+1]} = int (index($nameList[$i+1], $res) +
						(length($res) / 2)***REMOVED***
				}
			}
		}
		if ($SCREEN_MODE or ($block < 0)) {
			$numPad = length((sort { length($b) <=> length($a) } keys %keymap)[0]***REMOVED***
			$keyPad = length((sort { length($b) <=> length($a) } values %keymap)[0]***REMOVED***
		}
	}
	if ($SCREEN_MODE) {
		if (@$oldActString < 1) {
			print AWLOUT
							 $terminfo->cup(0, $width).
			             $actString->[0].
							 $terminfo->el()
	or wlreset(***REMOVED***
		}
	}
	my $last_net = '';
	foreach my $win (@wins) {
		my $global_hack_alert_tag_header;
		unless ($SCREEN_MODE) {
			$actString->[$line] = '' unless defined $actString->[$line]
					or Irssi::settings_get_bool(set 'all_disable'***REMOVED***
		}

		ref($win) or next;

		my $backup_win = Storable::dclone($win***REMOVED***
		ref($backup_win->{active}) or delete $backup_win->{active***REMOVED***
		if (Irssi::settings_get_str(set 'display_header') and 
				$last_net ne $backup_win->{active}{server}{tag}) {
			$global_hack_alert_tag_header = 1;
		}

		my $name = $win->get_active_name;
		$name = '*' if (Irssi::settings_get_bool('banned_channels_on') and exists
			$banned_channels{lc1459($name)}***REMOVED***
		$name = remove_uniform($name) if $name ne '*';
		$name = $win->{'name'} if $name ne '*' and $win->{'name'} ne ''
			and Irssi::settings_get_bool(set 'prefer_name'***REMOVED***
		my $active = $win->{'active'***REMOVED***
		my $colour = $win->{'hilight_color'***REMOVED***
		if (!defined $colour) { $colour = ''; }

		if ($win->{'data_level'} < abs Irssi::settings_get_int(set 'hide_data')
				&& ($win->{'refnum'} != Irssi::active_win->{'refnum'} || 0 <= Irssi::settings_get_int(set 'hide_data'))) {
			next; } # for Geert
		if (exists $awins{$win->{'refnum'}} && Irssi::settings_get_int(set 'hide_empty') && !$win->items
				&& ($win->{'refnum'} != Irssi::active_win->{'refnum'} || 0 <= Irssi::settings_get_int(set 'hide_empty'))) {
			next; }
		if    ($win->{'data_level'} == 0) { $hilight = '{sb_act_none '; } #'}'
		elsif ($win->{'data_level'} == 1) { $hilight = '{sb_act_text '; } #'}'
		elsif ($win->{'data_level'} == 2) { $hilight = '{sb_act_msg '; } #'}'
		elsif ($colour             ne '') { $hilight = "{sb_act_hilight_color $colour "; }
		elsif ($win->{'data_level'} == 3) { $hilight = '{sb_act_hilight '; } #'}'
		else                            ***REMOVED*** $hilight = '{sb_act_special '; } #'}'

		$number = $win->{'refnum'***REMOVED***
		my @display = ('display_nokey'***REMOVED***
		if (defined $keymap{$number} and $keymap{$number} ne '') {
			unshift @display, map { (my $cpy = $_) =~ s/_no/_/; $cpy } @display;
		}
		if (exists $awins{$number}) {
			unshift @display, map { my $cpy = $_; $cpy .= '_visible'; $cpy } @display;			
		}
		if (Irssi::active_win->{'refnum'} == $number) {
			unshift @display, map { my $cpy = $_; $cpy .= '_active'; $cpy }
				grep { !/_visible$/ } @display;
		}
		$display = (grep { $_ }
			map { Irssi::settings_get_str(set $_) }
			@display)[0];

		if ($global_hack_alert_tag_header) {
			$display = Irssi::settings_get_str(set 'display_header'***REMOVED***
			$name = $backup_win->{active}{server}{tag***REMOVED***
		}
			
		if ($SCREEN_MODE or Irssi::settings_get_bool(set 'sbar_maxlength')
				or ($block < 0)
		) {
			my $baseLength = sb_length(ir_escape(ir_ve(ir_parse_special_protected(sb_ctfe(
				'{sb_background}' . expand($display,
				C => ir_fe('x'),
				N => $number . (' 'x($numPad - length($number))),
				Q => ir_fe((' 'x($keyPad - length($keymap{$number}))) . $keymap{$number}),
				H => $hilight, #'{'
				S => '}{sb_background}'
			), 1), $win)))) - 1;
			my $uname = as_uni($name***REMOVED***
			my $diff = abs($block) - (screen_length($name) + $baseLength***REMOVED***
			if ($diff < 0) { # too long
				if (abs($diff) >= screen_length($name)) { $name = '' } # forget it
				elsif (abs($diff) + 1 >= screen_length($name)) { $name = as_tc(substr($uname,
						0, 1)***REMOVED*** }
				else {
					my $ulen = length $uname;
					for (
						my $middle2 = exists $abbrevList{$uname} ?
							(Irssi::settings_get_str('fancy_abbrev') =~ /^strict/i) ?
								2*$abbrevList{$uname} :
									(2*($abbrevList{$uname} + $ulen) / 3) :
							(Irssi::settings_get_str('fancy_abbrev') =~ /^head/i) ?
									2*$ulen :
							$ulen;
						$middle2 > -1 && length $uname > 1;
						--$middle2) {
						(substr $uname, $middle2/2, 2) = '~';
						my $sl = screen_length(as_tc($uname)***REMOVED***
						if ($sl + $baseLength < abs $block) {
							(substr $uname, $middle2/2, 1) = "\x{301c}";
							last;
						}
						elsif ($sl + $baseLength == abs $block) {
							last;
						}
					}
					$name = as_tc($uname***REMOVED***
				}
			}
			elsif ($SCREEN_MODE or ($block < 0)) {
				$name .= (' ' x $diff***REMOVED***
			}
		}

		my $add = ir_ve(ir_parse_special_protected(sb_ctfe('{sb_background}' . expand($display,
			C => ir_fe($name),
			N => $number . (' 'x($numPad - length($number))),
			Q => ir_fe((' 'x($keyPad - length($keymap{$number}))) . $keymap{$number}),
			H => $hilight, #{
			S => '}{sb_background}'
		), 1), $win)***REMOVED***
		if ($SCREEN_MODE) {
			$actString->[$line] = $add;
			if ((!defined $oldActString->[$line]
					or $oldActString->[$line] ne $actString->[$line])
					and
				$line <= ($columns * $height)
			) {
				print AWLOUT
								 $terminfo->cup(($line-1) % $height+1, $width + (
									 abs($block) * int(($line-1) / $height))).
				formats_to_ansi_basic(sb_expand(ir_escape($actString->[$line])))
	or wlreset(***REMOVED***
			}
			$line++;
		}
		else {
			$actString->[$line] = '' unless defined $actString->[$line];

			if (sb_length(ir_escape($actString->[$line] . $add)) >= $width) {
				$actString->[$line] .= ' ' x ($width - sb_length(ir_escape(
					$actString->[$line]))***REMOVED***
				$line++;
			}
			$actString->[$line] .= $add . $separator;
		}
		if ($global_hack_alert_tag_header) {
			$last_net = $backup_win->{active}{server}{tag***REMOVED***
			redo;
		}
	}

	if ($SCREEN_MODE) {
		while ($line <= ($columns * $height)) {
			print AWLOUT
							 $terminfo->cup(($line-1) % $height+1, $width + (
								 abs($block) * int(($line-1) / $height))).
							 $terminfo->el()
	or wlreset(***REMOVED***
			$line++;
		}
	}
	else {
		for (my $p = 0; $p < @$actString; $p++) { # wrap each line in
                                                  # {sb }, escape it
			my $x = $actString->[$p];             # properly, etc.
			$x =~ s/\Q$separator\E([ ]*)$/$1/;
			$x = "{sb $x}";
			$x = ir_escape($x***REMOVED***
			$actString->[$p] = $x;
		}
	}
}

sub eventChanged () { # Implement a change queue/blocker
	return if $BLOCK_ALL;
	unless ($_[0] && $_[0] eq 'TIMED') {
		if (defined $globTime) {
			Irssi::timeout_remove($globTime***REMOVED***
		} # delay the update further
		$globTime = Irssi::timeout_add_once(GLOB_QUEUE_TIMER, 'eventChanged', 'TIMED'***REMOVED***
		return;
	}
	$globTime = undef;
	my $temp = ($SCREEN_MODE ?
		"\\\n" . Irssi::settings_get_int(set 'block').
		Irssi::settings_get_int(set 'height_adjust')
		: "!\n" . Irssi::settings_get_str(set 'placement').
		Irssi::settings_get_int(set 'position')).
		Irssi::settings_get_str(set 'automode'***REMOVED***
	if ($temp ne $resetNeeded) { wlreset(***REMOVED*** return; }
	if ($FIRST_RUN) { $FIRST_RUN = undef; update_awins(***REMOVED*** return; }
	$needRemake = 1;

	if (
		($SCREEN_MODE)
			or
		($needRemake and Irssi::settings_get_bool(set 'all_disable'))
			or
		(!Irssi::settings_get_bool(set 'all_disable') and $currentLines < 1)
	) {
		$needRemake = undef;
		remake(***REMOVED***
	}

	unless ($SCREEN_MODE) {
		Irssi::timeout_add_once(100, 'syncLines', undef***REMOVED***

		for (keys %statusbars) {
			Irssi::statusbar_items_redraw(set$_***REMOVED***
		}
	}
	else {
		Irssi::timeout_add_once(100, 'syncColumns', undef***REMOVED***
	}
}

sub screenFullRedraw {
	my ($window) = @_;
	if (!ref $window or $window->{'refnum'} == Irssi::active_win->{'refnum'}) {
		$actString = [];
		eventChanged(***REMOVED***
	}
}

sub screenSize { # from nicklist.pl
	# get size
	my ($row, $col) = split ' ', `stty size`;
	# set screen width
	$screenWidth = $col-1;
	$screenHeight = $row-1;
	
	Irssi::timeout_add_once(100, sub {
		Irssi::timeout_add_once(10,sub {$screenResizing = 0; screenFullRedraw()}, []***REMOVED***
	}, $screenWidth***REMOVED***
}

sub fifoOff {
	close AWLOUT;
}

sub syncColumns {
	return if (@$actString == 0***REMOVED***
	my $temp = $currentColumns;
	my $height = $screenHeight - (Irssi::settings_get_int(set
			'height_adjust')***REMOVED***
	$currentColumns = int(($#$actString-1) / $height) + 1;
	my $currMaxColumns = Irssi::settings_get_int(set 'columns'***REMOVED***
	if ($currMaxColumns > 0 and $currentColumns > $currMaxColumns) {
		$currentColumns = $currMaxColumns;
	}
	elsif ($currMaxColumns < 0) {
		$currentColumns = abs($currMaxColumns***REMOVED***
	}
	return if ($temp == $currentColumns***REMOVED***
	screenSize(***REMOVED***
}

sub resizeTerm () {
	if ($SCREEN_MODE and !$screenResizing) {
		$screenResizing = 1;
		Irssi::timeout_add_once(10, 'screenSize', undef***REMOVED***
	}
	Irssi::timeout_add_once(100, 'eventChanged', undef***REMOVED***
}


Irssi::settings_add_str(setc, set 'display_nokey', '[$N]$H$C$S'***REMOVED***
Irssi::settings_add_str(setc, set 'display_key', '[$Q=$N]$H$C$S'***REMOVED***
Irssi::settings_add_str(setc, set 'display_nokey_visible', ''***REMOVED***
Irssi::settings_add_str(setc, set 'display_key_visible', ''***REMOVED***
Irssi::settings_add_str(setc, set 'display_nokey_active', ''***REMOVED***
Irssi::settings_add_str(setc, set 'display_key_active', ''***REMOVED***
Irssi::settings_add_str(setc, set 'display_header', ''***REMOVED***
Irssi::settings_add_str(setc, set 'separator', "\\ "***REMOVED***
Irssi::settings_add_bool(setc, set 'prefer_name', 0***REMOVED***
Irssi::settings_add_int(setc, set 'hide_empty', 0***REMOVED***
Irssi::settings_add_int(setc, set 'hide_data', 0***REMOVED***
Irssi::settings_add_int(setc, set 'maxlines', 9***REMOVED***
Irssi::settings_add_int(setc, set 'columns', 1***REMOVED***
Irssi::settings_add_int(setc, set 'block', 20***REMOVED***
Irssi::settings_add_bool(setc, set 'sbar_maxlength', 0***REMOVED***
Irssi::settings_add_int(setc, set 'height_adjust', 2***REMOVED***
Irssi::settings_add_str(setc, set 'sort', 'refnum'***REMOVED***
Irssi::settings_add_str(setc, set 'placement', 'bottom'***REMOVED***
Irssi::settings_add_int(setc, set 'position', 0***REMOVED***
Irssi::settings_add_bool(setc, set 'all_disable', 0***REMOVED***
Irssi::settings_add_str(setc, set 'automode', 'sbar'***REMOVED***
Irssi::settings_add_str(setc, set 'fifo', Irssi::get_irssi_dir . '/_windowlist'***REMOVED***


sub wlreset {
	$actString = [];
	$currentLines = 0;
	killOldStatus(***REMOVED***
	if ($MOUSE_ON) {
		Irssi::command_bind('mouse_xterm' => 'mouse_xterm'***REMOVED***
		Irssi::command('/^bind meta-[M /mouse_xterm'***REMOVED***
		Irssi::signal_add_first('gui key pressed' => 'mouse_key_hook'***REMOVED***
		mouse_enable(***REMOVED***
	}
	my $was_fifo_mode = $FIFO_MODE;
	if ($FIFO_MODE = (Irssi::settings_get_str(set 'automode') =~ /fifo/i)
			and
		!$was_fifo_mode
	) {
		my $path = Irssi::settings_get_str(set 'fifo'***REMOVED***
		if (!sysopen(AWLOUT, $path, O_WRONLY | O_NONBLOCK)) {
			Irssi::print("Couldn\'t write to the fifo ($!). Please make sure you ".
				"created the fifo and start reading it (\"cat $path\").", MSGLEVEL_CLIENTERROR***REMOVED***
			$SCREEN_MODE = $FIFO_MODE = undef;
		}
		else {
			$SCREEN_MODE = $FIFO_MODE;
			select AWLOUT; $|++;
			select STDOUT;
		}
	}
	elsif ($was_fifo_mode and !$FIFO_MODE) {
		$SCREEN_MODE = $FIFO_MODE;
		fifoOff(***REMOVED***
	}
	$resetNeeded = ($SCREEN_MODE ?
		"\\\n" . Irssi::settings_get_int(set 'block').
		Irssi::settings_get_int(set 'height_adjust')
		: "!\n" . Irssi::settings_get_str(set 'placement').
		Irssi::settings_get_int(set 'position')).
		Irssi::settings_get_str(set 'automode'***REMOVED***
	resizeTerm(***REMOVED***
}

Irssi::timeout_add_once(10, 'wlreset', undef***REMOVED***


my $Unload;
sub unload ($$$) {
	$Unload = 1;
	# pretend we didn't do anything ASAP
	Irssi::timeout_add_once(10, sub { $Unload = undef; }, undef***REMOVED***
}
# last try to catch a sigsegv
Irssi::signal_add_first('gui exit' => sub { $Unload = undef; }***REMOVED***
sub UNLOAD {
	if ($Unload) {
		$actString = [''];
		killOldStatus(***REMOVED***
		if ($FIFO_MODE) {
			fifoOff(***REMOVED***
		}
		if ($MOUSE_ON) {
			print STDERR "\e[?1000l"; # stop tracking
			Irssi::signal_remove('gui key pressed' => 'mouse_key_hook'***REMOVED***
			Irssi::command('/^bind -delete meta-[M'***REMOVED***
			Irssi::command_unbind('mouse_xterm' => 'mouse_xterm'***REMOVED***
		}
	}
}


sub addPrintTextHook { # update on print text
	return if $BLOCK_ALL;
	return if $_[0]->{'level'} == 262144 and $_[0]->{'target'} eq ''
			and !defined($_[0]->{'server'}***REMOVED***
	if (Irssi::settings_get_str(set 'sort') =~ /^[-!]?last_line$/) {
		Irssi::timeout_add_once(100, 'eventChanged', undef***REMOVED***
	}
}

sub distort_event_window_change {
	Irssi::signal_continue($_[0], undef, @_[1..$#_])
}

sub update_awins {
	return if $BLOCK_ALL;
	unless ($_[0] && $_[0] eq 'TIMED') {
		if (defined $globTime2) {
			Irssi::timeout_remove($globTime2***REMOVED***
		} # delay the update further
		$globTime2 = Irssi::timeout_add_once(GLOB_QUEUE_TIMER, 'update_awins', 'TIMED'***REMOVED***
		return;
	}
	$globTime2 = undef;
	{
		Irssi::signal_add_first('window changed' => 'distort_event_window_change'***REMOVED***
		local $BLOCK_ALL = 1;
		my $wins = @{[Irssi::windows]***REMOVED***
		%awins = (***REMOVED***
		my $bwin = 
			my $awin = Irssi::active_win;
		$awin->command('window last'***REMOVED***
		my $lwin = Irssi::active_win;
		$lwin->command('window last'***REMOVED***
		my $awin_counter = 0;
		do {
			Irssi::active_win->command('window up'***REMOVED***
			$awin = Irssi::active_win;
			$awins{$awin->{'refnum'}} = undef;
			++$awin_counter;
		} until ($awin->{'refnum'} == $bwin->{'refnum'} || $awin_counter >= $wins***REMOVED***
		$awin->command('window '.$lwin->{'refnum'}***REMOVED***
		Irssi::active_win->command('window last'***REMOVED***
		Irssi::signal_remove('window changed' => 'distort_event_window_change'***REMOVED***
	}
	&eventChanged;
}

Irssi::signal_add_first({
	'command script unload' => 'unload',
}***REMOVED***
Irssi::signal_add_last({
	'setup changed' => 'eventChanged',
	'print text' => 'addPrintTextHook',
	'terminal resized' => 'resizeTerm',
	'setup reread' => 'wlreset',
	'window hilight' => 'eventChanged',
}***REMOVED***
Irssi::signal_add({
	'window changed' => 'update_awins',
	'window item changed' => 'eventChanged',
	'window changed automatic' => 'update_awins',
	'window created' => 'update_awins',
	'window destroyed' => 'update_awins',
	'window name changed' => 'eventChanged',
	'window refnum changed' => 'eventChanged',
}***REMOVED***

# Mouse script by Wouter Coekaerts: http://wouter.coekaerts.be/site/irssi/mouse
# based on irssi mouse patch by mirage: http://darksun.com.pt/mirage/irssi/

my $mouse_xterm_status = -1; # -1:off 0,1,2:filling mouse_xterm_combo
my @mouse_xterm_combo; # 0:button 1:x 2:y
my @mouse_xterm_previous; # previous contents of mouse_xterm_combo

sub mouse_xterm_off {
	$mouse_xterm_status = -1;
}
sub mouse_xterm {
	$mouse_xterm_status = 0;
	Irssi::timeout_add_once(10, 'mouse_xterm_off', undef***REMOVED***
}
sub mouse_enable {
	print STDERR "\e[?1000h"; # start tracking
}
	
sub mouse_event {
	if ($_[2] < $currentLines) {
		if ($_[0] == 3 and $_[3] == 0 and
				$_[1] == $_[4] and $_[2] == $_[5]) {
			$_[1] -= sb_length('{sb x}') / 2; return unless $_[1] > -1;
			my $win;
			if (!$SCREEN_MODE and
				Irssi::settings_get_int(set 'block') < 0) {
				$win = int($_[1] / abs(Irssi::settings_get_int(set 'block'))***REMOVED***
				$win += 1;
				$win += $_[2] * int(([Irssi::windows]->[0]{'width'} - sb_length('{sb x}')) /
					abs(Irssi::settings_get_int(set 'block'))***REMOVED***
			}
			Irssi::command('window ' . $win***REMOVED***
		}
	}
	elsif ($_[0] == 3 and ($_[3] == 64 or $_[3] == 65) and
			$_[1] == $_[4] and $_[2] == $_[5]) {
		my $cmd = '/scrollback goto ' . ($_[3] == 64 ? '-' : '+') . '10';
		Irssi::signal_emit('send command', $cmd,
			Irssi::active_win->{'active_server'}, Irssi::active_win->{'active'})
	}
	elsif ($_[3] == 3 and ($_[0] == 64 or $_[0] == 65) and
			$_[1] == $_[4] and $_[2] == $_[5]) {
	}
	else {
		print STDERR "\e[?1000l"; # stop tracking
		Irssi::timeout_add_once(1000, 'mouse_enable', undef***REMOVED***
	}
}

sub mouse_key_hook {
	my ($key) = @_;
	if ($mouse_xterm_status != -1) {
		if ($mouse_xterm_status == 0) {
			@mouse_xterm_previous = @mouse_xterm_combo;
		}
		$mouse_xterm_combo[$mouse_xterm_status] = $key-32;
		$mouse_xterm_status++;
		if ($mouse_xterm_status == 3) {
			$mouse_xterm_status = -1;
			# match screen coordinates
			$mouse_xterm_combo[1]--;
			$mouse_xterm_combo[2]--;
			mouse_event(@mouse_xterm_combo[0 .. 2], @mouse_xterm_previous[0 .. 2]***REMOVED***
		}
		Irssi::signal_stop(***REMOVED***
	}
}

sub runsub {
	my ($cmd) = @_;
	sub {
		my ($data, $server, $item) = @_;
		Irssi::command_runsub($cmd, $data, $server, $item***REMOVED***
	***REMOVED***
}
Irssi::command_bind( setc() => runsub(setc()) ***REMOVED***
Irssi::command_bind(
	setc() . ' redraw' => sub {
		return unless $SCREEN_MODE;
		screenFullRedraw(***REMOVED***
	}
***REMOVED***
		

# Algorithm::LCSS module (from CPAN)
{
	package Algorithm::Diff;
	use strict;

	use integer;

	# McIlroy-Hunt diff algorithm
	# Adapted from the Smalltalk code of Mario I. Wolczko, <mario@wolczko.com>
	# by Ned Konz, perl@bike-nomad.com
	# Updates by Tye McQueen, http://perlmonks.org/?node=tye

	sub _withPositionsOfInInterval
	{
		 my $aCollection = shift;    # array ref
		 my $start       = shift;
		 my $end         = shift;
		 my $keyGen      = shift;
		 my %d;
		 my $index;
		 for ( $index = $start ; $index <= $end ; $index++ )
		 {
			  my $element = $aCollection->[$index];
			  my $key = &$keyGen( $element, @_ ***REMOVED***
			  if ( exists( $d{$key} ) )
			***REMOVED***
					unshift ( @{ $d{$key} }, $index ***REMOVED***
			***REMOVED***
			  else
			***REMOVED***
					$d{$key} = [$index];
			***REMOVED***
		 }
		 return wantarray ? %d : \%d;
	}

	sub _replaceNextLargerWith
	{
		 my ( $array, $aValue, $high ) = @_;
		 $high ||= $#$array;

		 # off the end?
		 if ( $high == -1 || $aValue > $array->[-1] )
		 {
			  push ( @$array, $aValue ***REMOVED***
			  return $high + 1;
		 }

		 # binary search for insertion point...
		 my $low = 0;
		 my $index;
		 my $found;
		 while ( $low <= $high )
		 {
			  $index = ( $high + $low ) / 2;

			  # $index = int(( $high + $low ) / 2***REMOVED***  # without 'use integer'
			  $found = $array->[$index];

			  if ( $aValue == $found )
			***REMOVED***
					return undef;
			***REMOVED***
			  elsif ( $aValue > $found )
			***REMOVED***
					$low = $index + 1;
			***REMOVED***
			  else
			***REMOVED***
					$high = $index - 1;
			***REMOVED***
		 }

		 # now insertion point is in $low.
		 $array->[$low] = $aValue;    # overwrite next larger
		 return $low;
	}

	sub _longestCommonSubsequence
	{
		 my $a        = shift;    # array ref or hash ref
		 my $b        = shift;    # array ref or hash ref
		 my $counting = shift;    # scalar
		 my $keyGen   = shift;    # code ref
		 my $compare;             # code ref

		 if ( ref($a) eq 'HASH' )
		 {                        # prepared hash must be in $b
			  my $tmp = $b;
			  $b = $a;
			  $a = $tmp;
		 }

		 # Check for bogus (non-ref) argument values
		 if ( !ref($a) || !ref($b) )
		 {
			  my @callerInfo = caller(1***REMOVED***
			  die 'error: must pass array or hash references to ' . $callerInfo[3];
		 }

		 # set up code refs
		 # Note that these are optimized.
		 if ( !defined($keyGen) )    # optimize for strings
		 {
			  $keyGen = sub { $_[0] ***REMOVED***
			  $compare = sub { my ( $a, $b ) = @_; $a eq $b ***REMOVED***
		 }
		 else
		 {
			  $compare = sub {
					my $a = shift;
					my $b = shift;
					&$keyGen( $a, @_ ) eq &$keyGen( $b, @_ ***REMOVED***
			***REMOVED***;
		 }

		 my ( $aStart, $aFinish, $matchVector ) = ( 0, $#$a, [] ***REMOVED***
		 my ( $prunedCount, $bMatches ) = ( 0, {} ***REMOVED***

		 if ( ref($b) eq 'HASH' )    # was $bMatches prepared for us?
		 {
			  $bMatches = $b;
		 }
		 else
		 {
			  my ( $bStart, $bFinish ) = ( 0, $#$b ***REMOVED***

			  # First we prune off any common elements at the beginning
			  while ( $aStart <= $aFinish
					and $bStart <= $bFinish
					and &$compare( $a->[$aStart], $b->[$bStart], @_ ) )
			***REMOVED***
					$matchVector->[ $aStart++ ] = $bStart++;
					$prunedCount++;
			***REMOVED***

			  # now the end
			  while ( $aStart <= $aFinish
					and $bStart <= $bFinish
					and &$compare( $a->[$aFinish], $b->[$bFinish], @_ ) )
			***REMOVED***
					$matchVector->[ $aFinish-- ] = $bFinish--;
					$prunedCount++;
			***REMOVED***

			  # Now compute the equivalence classes of positions of elements
			  $bMatches =
				 _withPositionsOfInInterval( $b, $bStart, $bFinish, $keyGen, @_ ***REMOVED***
		 }
		 my $thresh = [];
		 my $links  = [];

		 my ( $i, $ai, $j, $k ***REMOVED***
		 for ( $i = $aStart ; $i <= $aFinish ; $i++ )
		 {
			  $ai = &$keyGen( $a->[$i], @_ ***REMOVED***
			  if ( exists( $bMatches->{$ai} ) )
			***REMOVED***
					$k = 0;
					for $j ( @{ $bMatches->{$ai} } )
					{

						 # optimization: most of the time this will be true
						 if ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j )
						 {
							  $thresh->[$k] = $j;
						 }
						 else
						 {
							  $k = _replaceNextLargerWith( $thresh, $j, $k ***REMOVED***
						 }

						 # oddly, it's faster to always test this (CPU cache?).
						 if ( defined($k) )
						 {
							  $links->[$k] =
								 [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
						 }
					}
			***REMOVED***
		 }

		 if (@$thresh)
		 {
			  return $prunedCount + @$thresh if $counting;
			  for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] )
			***REMOVED***
					$matchVector->[ $link->[1] ] = $link->[2];
			***REMOVED***
		 }
		 elsif ($counting)
		 {
			  return $prunedCount;
		 }

		 return wantarray ? @$matchVector : $matchVector;
	}

	sub traverse_sequences
	{
		 my $a                 = shift;          # array ref
		 my $b                 = shift;          # array ref
		 my $callbacks         = shift || {***REMOVED***
		 my $keyGen            = shift;
		 my $matchCallback     = $callbacks->{'MATCH'} || sub { ***REMOVED***
		 my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { ***REMOVED***
		 my $finishedACallback = $callbacks->{'A_FINISHED'***REMOVED***
		 my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { ***REMOVED***
		 my $finishedBCallback = $callbacks->{'B_FINISHED'***REMOVED***
		 my $matchVector = _longestCommonSubsequence( $a, $b, 0, $keyGen, @_ ***REMOVED***

		 # Process all the lines in @$matchVector
		 my $lastA = $#$a;
		 my $lastB = $#$b;
		 my $bi    = 0;
		 my $ai;

		 for ( $ai = 0 ; $ai <= $#$matchVector ; $ai++ )
		 {
			  my $bLine = $matchVector->[$ai];
			  if ( defined($bLine) )    # matched
			***REMOVED***
					&$discardBCallback( $ai, $bi++, @_ ) while $bi < $bLine;
					&$matchCallback( $ai,    $bi++, @_ ***REMOVED***
			***REMOVED***
			  else
			***REMOVED***
					&$discardACallback( $ai, $bi, @_ ***REMOVED***
			***REMOVED***
		 }

		 # The last entry (if any) processed was a match.
		 # $ai and $bi point just past the last matching lines in their sequences.

		 while ( $ai <= $lastA or $bi <= $lastB )
		 {

			  # last A?
			  if ( $ai == $lastA + 1 and $bi <= $lastB )
			***REMOVED***
					if ( defined($finishedACallback) )
					{
						 &$finishedACallback( $lastA, @_ ***REMOVED***
						 $finishedACallback = undef;
					}
					else
					{
						 &$discardBCallback( $ai, $bi++, @_ ) while $bi <= $lastB;
					}
			***REMOVED***

			  # last B?
			  if ( $bi == $lastB + 1 and $ai <= $lastA )
			***REMOVED***
					if ( defined($finishedBCallback) )
					{
						 &$finishedBCallback( $lastB, @_ ***REMOVED***
						 $finishedBCallback = undef;
					}
					else
					{
						 &$discardACallback( $ai++, $bi, @_ ) while $ai <= $lastA;
					}
			***REMOVED***

			  &$discardACallback( $ai++, $bi, @_ ) if $ai <= $lastA;
			  &$discardBCallback( $ai, $bi++, @_ ) if $bi <= $lastB;
		 }

		 return 1;
	}

	sub traverse_balanced
	{
		 my $a                 = shift;              # array ref
		 my $b                 = shift;              # array ref
		 my $callbacks         = shift || {***REMOVED***
		 my $keyGen            = shift;
		 my $matchCallback     = $callbacks->{'MATCH'} || sub { ***REMOVED***
		 my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { ***REMOVED***
		 my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { ***REMOVED***
		 my $changeCallback    = $callbacks->{'CHANGE'***REMOVED***
		 my $matchVector = _longestCommonSubsequence( $a, $b, 0, $keyGen, @_ ***REMOVED***

		 # Process all the lines in match vector
		 my $lastA = $#$a;
		 my $lastB = $#$b;
		 my $bi    = 0;
		 my $ai    = 0;
		 my $ma    = -1;
		 my $mb;

		 while (1)
		 {

			  # Find next match indices $ma and $mb
			  do {
					$ma++;
			***REMOVED*** while(
						 $ma <= $#$matchVector
					&&  !defined $matchVector->[$ma]
			  ***REMOVED***

			  last if $ma > $#$matchVector;    # end of matchVector?
			  $mb = $matchVector->[$ma];

			  # Proceed with discard a/b or change events until
			  # next match
			  while ( $ai < $ma || $bi < $mb )
			***REMOVED***

					if ( $ai < $ma && $bi < $mb )
					{

						 # Change
						 if ( defined $changeCallback )
						 {
							  &$changeCallback( $ai++, $bi++, @_ ***REMOVED***
						 }
						 else
						 {
							  &$discardACallback( $ai++, $bi, @_ ***REMOVED***
							  &$discardBCallback( $ai, $bi++, @_ ***REMOVED***
						 }
					}
					elsif ( $ai < $ma )
					{
						 &$discardACallback( $ai++, $bi, @_ ***REMOVED***
					}
					else
					{

						 # $bi < $mb
						 &$discardBCallback( $ai, $bi++, @_ ***REMOVED***
					}
			***REMOVED***

			  # Match
			  &$matchCallback( $ai++, $bi++, @_ ***REMOVED***
		 }

		 while ( $ai <= $lastA || $bi <= $lastB )
		 {
			  if ( $ai <= $lastA && $bi <= $lastB )
			***REMOVED***

					# Change
					if ( defined $changeCallback )
					{
						 &$changeCallback( $ai++, $bi++, @_ ***REMOVED***
					}
					else
					{
						 &$discardACallback( $ai++, $bi, @_ ***REMOVED***
						 &$discardBCallback( $ai, $bi++, @_ ***REMOVED***
					}
			***REMOVED***
			  elsif ( $ai <= $lastA )
			***REMOVED***
					&$discardACallback( $ai++, $bi, @_ ***REMOVED***
			***REMOVED***
			  else
			***REMOVED***

					# $bi <= $lastB
					&$discardBCallback( $ai, $bi++, @_ ***REMOVED***
			***REMOVED***
		 }

		 return 1;
	}

	sub prepare
	{
		 my $a       = shift;    # array ref
		 my $keyGen  = shift;    # code ref

		 # set up code ref
		 $keyGen = sub { $_[0] } unless defined($keyGen***REMOVED***

		 return scalar _withPositionsOfInInterval( $a, 0, $#$a, $keyGen, @_ ***REMOVED***
	}

	sub LCS
	{
		 my $a = shift;                  # array ref
		 my $b = shift;                  # array ref or hash ref
		 my $matchVector = _longestCommonSubsequence( $a, $b, 0, @_ ***REMOVED***
		 my @retval;
		 my $i;
		 for ( $i = 0 ; $i <= $#$matchVector ; $i++ )
		 {
			  if ( defined( $matchVector->[$i] ) )
			***REMOVED***
					push ( @retval, $a->[$i] ***REMOVED***
			***REMOVED***
		 }
		 return wantarray ? @retval : \@retval;
	}

	sub LCS_length
	{
		 my $a = shift;                          # array ref
		 my $b = shift;                          # array ref or hash ref
		 return _longestCommonSubsequence( $a, $b, 1, @_ ***REMOVED***
	}

	sub LCSidx
	{
		 my $a= shift @_;
		 my $b= shift @_;
		 my $match= _longestCommonSubsequence( $a, $b, 0, @_ ***REMOVED***
		 my @am= grep defined $match->[$_], 0..$#$match;
		 my @bm= @{$match}[@am];
		 return \@am, \@bm;
	}

	sub compact_diff
	{
		 my $a= shift @_;
		 my $b= shift @_;
		 my( $am, $bm )= LCSidx( $a, $b, @_ ***REMOVED***
		 my @cdiff;
		 my( $ai, $bi )= ( 0, 0 ***REMOVED***
		 push @cdiff, $ai, $bi;
		 while( 1 ) {
			  while(  @$am  &&  $ai == $am->[0]  &&  $bi == $bm->[0]  ) {
					shift @$am;
					shift @$bm;
					++$ai, ++$bi;
			***REMOVED***
			  push @cdiff, $ai, $bi;
			  last   if  ! @$am;
			  $ai = $am->[0];
			  $bi = $bm->[0];
			  push @cdiff, $ai, $bi;
		 }
		 push @cdiff, 0+@$a, 0+@$b
			  if  $ai < @$a || $bi < @$b;
		 return wantarray ? @cdiff : \@cdiff;
	}

	sub diff
	{
		 my $a      = shift;    # array ref
		 my $b      = shift;    # array ref
		 my $retval = [];
		 my $hunk   = [];
		 my $discard = sub {
			  push @$hunk, [ '-', $_[0], $a->[ $_[0] ] ];
		 ***REMOVED***
		 my $add = sub {
			  push @$hunk, [ '+', $_[1], $b->[ $_[1] ] ];
		 ***REMOVED***
		 my $match = sub {
			  push @$retval, $hunk
					if 0 < @$hunk;
			  $hunk = []
		 ***REMOVED***
		 traverse_sequences( $a, $b,
			***REMOVED*** MATCH => $match, DISCARD_A => $discard, DISCARD_B => $add }, @_ ***REMOVED***
		 &$match(***REMOVED***
		 return wantarray ? @$retval : $retval;
	}

	sub sdiff
	{
		 my $a      = shift;    # array ref
		 my $b      = shift;    # array ref
		 my $retval = [];
		 my $discard = sub { push ( @$retval, [ '-', $a->[ $_[0] ], "" ] ) ***REMOVED***
		 my $add = sub { push ( @$retval, [ '+', "", $b->[ $_[1] ] ] ) ***REMOVED***
		 my $change = sub {
			  push ( @$retval, [ 'c', $a->[ $_[0] ], $b->[ $_[1] ] ] ***REMOVED***
		 ***REMOVED***
		 my $match = sub {
			  push ( @$retval, [ 'u', $a->[ $_[0] ], $b->[ $_[1] ] ] ***REMOVED***
		 ***REMOVED***
		 traverse_balanced(
			  $a,
			  $b,
			***REMOVED***
					MATCH     => $match,
					DISCARD_A => $discard,
					DISCARD_B => $add,
					CHANGE    => $change,
			***REMOVED***
			  @_
		 ***REMOVED***
		 return wantarray ? @$retval : $retval;
	}

	my $Root= __PACKAGE__;
	package Algorithm::Diff::_impl;
	use strict;

	sub _Idx()***REMOVED*** 0 } # $me->[_Idx]: Ref to array of hunk indices
					# 1   # $me->[1]: Ref to first sequence
					# 2   # $me->[2]: Ref to second sequence
	sub _End()***REMOVED*** 3 } # $me->[_End]: Diff between forward and reverse pos
	sub _Same() { 4 } # $me->[_Same]: 1 if pos 1 contains unchanged items
	sub _Base() { 5 } # $me->[_Base]: Added to range's min and max
	sub _Pos()***REMOVED*** 6 } # $me->[_Pos]: Which hunk is currently selected
	sub _Off()***REMOVED*** 7 } # $me->[_Off]: Offset into _Idx for current position
	sub _Min() { -2 } # Added to _Off to get min instead of max+1

	sub Die
	{
		 require Carp;
		 Carp::confess( @_ ***REMOVED***
	}

	sub _ChkPos
	{
		 my( $me )= @_;
		 return   if  $me->[_Pos];
		 my $meth= ( caller(1) )[3];
		 Die( "Called $meth on 'reset' object" ***REMOVED***
	}

	sub _ChkSeq
	{
		 my( $me, $seq )= @_;
		 return $seq + $me->[_Off]
			  if  1 == $seq  ||  2 == $seq;
		 my $meth= ( caller(1) )[3];
		 Die( "$meth: Invalid sequence number ($seq***REMOVED*** must be 1 or 2" ***REMOVED***
	}

	sub getObjPkg
	{
		 my( $us )= @_;
		 return ref $us   if  ref $us;
		 return $us . "::_obj";
	}

	sub new
	{
		 my( $us, $seq1, $seq2, $opts ) = @_;
		 my @args;
		 for( $opts->{keyGen} ) {
			  push @args, $_   if  $_;
		 }
		 for( $opts->{keyGenArgs} ) {
			  push @args, @$_   if  $_;
		 }
		 my $cdif= Algorithm::Diff::compact_diff( $seq1, $seq2, @args ***REMOVED***
		 my $same= 1;
		 if(  0 == $cdif->[2]  &&  0 == $cdif->[3]  ) {
			  $same= 0;
			  splice @$cdif, 0, 2;
		 }
		 my @obj= ( $cdif, $seq1, $seq2 ***REMOVED***
		 $obj[_End] = (1+@$cdif)/2;
		 $obj[_Same] = $same;
		 $obj[_Base] = 0;
		 my $me = bless \@obj, $us->getObjPkg(***REMOVED***
		 $me->Reset( 0 ***REMOVED***
		 return $me;
	}

	sub Reset
	{
		 my( $me, $pos )= @_;
		 $pos= int( $pos || 0 ***REMOVED***
		 $pos += $me->[_End]
			  if  $pos < 0;
		 $pos= 0
			  if  $pos < 0  ||  $me->[_End] <= $pos;
		 $me->[_Pos]= $pos || !1;
		 $me->[_Off]= 2*$pos - 1;
		 return $me;
	}

	sub Base
	{
		 my( $me, $base )= @_;
		 my $oldBase= $me->[_Base];
		 $me->[_Base]= 0+$base   if  defined $base;
		 return $oldBase;
	}

	sub Copy
	{
		 my( $me, $pos, $base )= @_;
		 my @obj= @$me;
		 my $you= bless \@obj, ref($me***REMOVED***
		 $you->Reset( $pos )   if  defined $pos;
		 $you->Base( $base ***REMOVED***
		 return $you;
	}

	sub Next {
		 my( $me, $steps )= @_;
		 $steps= 1   if  ! defined $steps;
		 if( $steps ) {
			  my $pos= $me->[_Pos];
			  my $new= $pos + $steps;
			  $new= 0   if  $pos  &&  $new < 0;
			  $me->Reset( $new )
		 }
		 return $me->[_Pos];
	}

	sub Prev {
		 my( $me, $steps )= @_;
		 $steps= 1   if  ! defined $steps;
		 my $pos= $me->Next(-$steps***REMOVED***
		 $pos -= $me->[_End]   if  $pos;
		 return $pos;
	}

	sub Diff {
		 my( $me )= @_;
		 $me->_ChkPos(***REMOVED***
		 return 0   if  $me->[_Same] == ( 1 & $me->[_Pos] ***REMOVED***
		 my $ret= 0;
		 my $off= $me->[_Off];
		 for my $seq ( 1, 2 ) {
			  $ret |= $seq
					if  $me->[_Idx][ $off + $seq + _Min ]
					<   $me->[_Idx][ $off + $seq ];
		 }
		 return $ret;
	}

	sub Min {
		 my( $me, $seq, $base )= @_;
		 $me->_ChkPos(***REMOVED***
		 my $off= $me->_ChkSeq($seq***REMOVED***
		 $base= $me->[_Base] if !defined $base;
		 return $base + $me->[_Idx][ $off + _Min ];
	}

	sub Max {
		 my( $me, $seq, $base )= @_;
		 $me->_ChkPos(***REMOVED***
		 my $off= $me->_ChkSeq($seq***REMOVED***
		 $base= $me->[_Base] if !defined $base;
		 return $base + $me->[_Idx][ $off ] -1;
	}

	sub Range {
		 my( $me, $seq, $base )= @_;
		 $me->_ChkPos(***REMOVED***
		 my $off = $me->_ChkSeq($seq***REMOVED***
		 if( !wantarray ) {
			  return  $me->[_Idx][ $off ]
					-   $me->[_Idx][ $off + _Min ];
		 }
		 $base= $me->[_Base] if !defined $base;
		 return  ( $base + $me->[_Idx][ $off + _Min ] )
			  ..  ( $base + $me->[_Idx][ $off ] - 1 ***REMOVED***
	}

	sub Items {
		 my( $me, $seq )= @_;
		 $me->_ChkPos(***REMOVED***
		 my $off = $me->_ChkSeq($seq***REMOVED***
		 if( !wantarray ) {
			  return  $me->[_Idx][ $off ]
					-   $me->[_Idx][ $off + _Min ];
		 }
		 return
			  @{$me->[$seq]}[
						 $me->[_Idx][ $off + _Min ]
					..  ( $me->[_Idx][ $off ] - 1 )
			  ];
	}

	sub Same {
		 my( $me )= @_;
		 $me->_ChkPos(***REMOVED***
		 return wantarray ? () : 0
			  if  $me->[_Same] != ( 1 & $me->[_Pos] ***REMOVED***
		 return $me->Items(1***REMOVED***
	}

	my %getName;
		 %getName= (
			  same => \&Same,
			  diff => \&Diff,
			  base => \&Base,
			  min  => \&Min,
			  max  => \&Max,
			  range=> \&Range,
			  items=> \&Items, # same thing
		 ***REMOVED***

	sub Get
	{
		 my $me= shift @_;
		 $me->_ChkPos(***REMOVED***
		 my @value;
		 for my $arg (  @_  ) {
			  for my $word (  split ' ', $arg  ) {
					my $meth;
					if(     $word !~ /^(-?\d+)?([a-zA-Z]+)([12])?$/
						 ||  not  $meth= $getName{ lc $2 }
					) {
						 Die( $Root, ", Get: Invalid request ($word)" ***REMOVED***
					}
					my( $base, $name, $seq )= ( $1, $2, $3 ***REMOVED***
					push @value, scalar(
						 4 == length($name)
							  ? $meth->( $me )
							  : $meth->( $me, $seq, $base )
					***REMOVED***
			***REMOVED***
		 }
		 if(  wantarray  ) {
			  return @value;
		 } elsif(  1 == @value  ) {
			  return $value[0];
		 }
		 Die( 0+@value, " values requested from ",
			  $Root, "'s Get in scalar context" ***REMOVED***
	}


	my $Obj= getObjPkg($Root***REMOVED***
	no strict 'refs';

	for my $meth (  qw( new getObjPkg )  ) {
		 *{$Root."::".$meth} = \&{$meth***REMOVED***
		 *{$Obj ."::".$meth} = \&{$meth***REMOVED***
	}
	for my $meth (  qw(
		 Next Prev Reset Copy Base Diff
		 Same Items Range Min Max Get
		 _ChkPos _ChkSeq
	)  ) {
		 *{$Obj."::".$meth} = \&{$meth***REMOVED***
	}

***REMOVED***
{
	package Algorithm::LCSS;

	use strict;
	{
		no strict 'refs';
		*traverse_sequences = \&Algorithm::Diff::traverse_sequences;
	}

	sub _tokenize { [split //, $_[0]] }

	sub CSS {
		 my $is_array = ref $_[0] eq 'ARRAY' ? 1 : 0;
		 my ( $seq1, $seq2, @match, $from_match ***REMOVED***
		 my $i = 0;
		 if ( $is_array ) {
			  $seq1 = $_[0];
			  $seq2 = $_[1];
			  traverse_sequences( $seq1, $seq2, {
					MATCH => sub { push @{$match[$i]}, $seq1->[$_[0]]; $from_match = 1 },
					DISCARD_A => sub { do{$i++; $from_match = 0} if $from_match },
					DISCARD_B => sub { do{$i++; $from_match = 0} if $from_match },
			***REMOVED******REMOVED***
		 }
		 else {
			  $seq1 = _tokenize($_[0]***REMOVED***
			  $seq2 = _tokenize($_[1]***REMOVED***
			  traverse_sequences( $seq1, $seq2, {
					MATCH => sub { $match[$i] .= $seq1->[$_[0]]; $from_match = 1 },
					DISCARD_A => sub { do{$i++; $from_match = 0} if $from_match },
					DISCARD_B => sub { do{$i++; $from_match = 0} if $from_match },
			***REMOVED******REMOVED***
		 }
	  return \@match;
	}

	sub CSS_Sorted {
		 my $match = CSS(@_***REMOVED***
		 if ( ref $_[0] eq 'ARRAY' ) {
			 @$match = map{$_->[0]}sort{$b->[1]<=>$a->[1]}map{[$_,scalar(@$_)]}@$match
		 }
		 else {
			 @$match = map{$_->[0]}sort{$b->[1]<=>$a->[1]}map{[$_,length($_)]}@$match
		 }
	  return $match;
	}

	sub LCSS {
		 my $is_array = ref $_[0] eq 'ARRAY' ? 1 : 0;
		 my $css = CSS(@_***REMOVED***
		 my $index;
		 my $length = 0;
		 if ( $is_array ) {
			  for( my $i = 0; $i < @$css; $i++ ) {
					next unless @{$css->[$i]}>$length;
					$index = $i;
					$length = @{$css->[$i]***REMOVED***
			***REMOVED***
		 }
		 else {
			  for( my $i = 0; $i < @$css; $i++ ) {
					next unless length($css->[$i])>$length;
					$index = $i;
					$length = length($css->[$i]***REMOVED***
			***REMOVED***
		 }
	  return $css->[$index];
	}

***REMOVED***

# Class::Classless module (from CPAN)
{
	package Class::Classless;
	use strict;
	use vars qw(@ISA***REMOVED***
	use Carp;

	@ISA = (***REMOVED***
	@Class::Classless::X::ISA = (***REMOVED***

	sub Class::Classless::X::AUTOLOAD {
	  my $it = shift @_;
	  my $m =  ($Class::Classless::X::AUTOLOAD =~ m/([^:]+)$/s ) 
					 ? $1 : $Class::Classless::X::AUTOLOAD;

	  croak "Can't call Class::Classless methods (like $m) without an object"
		 unless ref $it;  # sanity, basically.

	  my $prevstate;
	  $prevstate = ${shift @_}
		if scalar(@_) && defined($_[0]) &&
			ref($_[0]) eq 'Class::Classless::CALLSTATE::SHIMMY'
	  ;   # A shim!  we were called via $callstate->NEXT

	  my $no_fail = $prevstate ? $prevstate->[3] : undef;
	  my $i       = $prevstate ? ($prevstate->[1] + 1) : 0;
		# where to start scanning
	  my $lineage;

	  # Get the linearization of the ISA tree
	  if($prevstate) {
		 $lineage = $prevstate->[2];
	***REMOVED*** elsif(defined $it->{'ISA_CACHE'} and ref $it->{'ISA_CACHE'} ){
		 $lineage = $it->{'ISA_CACHE'***REMOVED***
	***REMOVED*** else {
		 $lineage = [ &Class::Classless::X::ISA_TREE($it) ];
	***REMOVED***

	  for(; $i < @$lineage; ++$i) {

		 if( !defined($no_fail) and exists($lineage->[$i]{'NO_FAIL'}) ) {
			$no_fail = ($lineage->[$i]{'NO_FAIL'} || 0***REMOVED***
			# so the first NO_FAIL sets it
		 }

		 if(     ref($lineage->[$i]{'METHODS'}     || 0)  # sanity
			&& exists($lineage->[$i]{'METHODS'}{$m})
		 ){
			# We found what we were after.  Now see what to do with it.
			my $v = $lineage->[$i]{'METHODS'}{$m***REMOVED***
			return $v unless defined $v and ref $v;

			if(ref($v) eq 'CODE') { # normal case, I expect!
			  # Used to have copying of the arglist here.
			  #  But it was apparently useless, so I deleted it
			  unshift @_, 
				 $it,                   # $_[0]    -- target object
				 # a NEW callstate
				 bless([$m, $i, $lineage, $no_fail, $prevstate ? 1 : 0],
						 'Class::Classless::CALLSTATE'
						),                # $_[1]    -- the callstate
			  ;
			  goto &{ $v ***REMOVED*** # yes, magic goto!  bimskalabim!
			}
			return @$v if ref($v) eq '_deref_array';
			return $$v if ref($v) eq '_deref_scalar';
			return $v; # fallthru
		 }
	***REMOVED***

	  if($m eq 'DESTROY') { # mitigate DESTROY-lookup failure at global destruction
		 # should be impossible
	***REMOVED*** else {
		 if($no_fail || 0) {
			return;
		 }
		 croak "Can't find ", $prevstate ? 'NEXT method' : 'method',
				 " $m in ", $it->{'NAME'} || $it,
				 " or any ancestors\n";
	***REMOVED***
	}

	sub Class::Classless::X::DESTROY {
	  # noop
	}

	sub Class::Classless::X::ISA_TREE {
	  use strict;
	  my $set_cache = 0; # flag to set the cache on the way out

	  if(exists($_[0]{'ISA_CACHE'})) {
		 return    @{$_[0]{'ISA_CACHE'}}
		  if defined $_[0]{'ISA_CACHE'}
			  and ref $_[0]{'ISA_CACHE'***REMOVED***

		 # Otherwise, if exists but is not a ref, it's a signal that it should
		 #  be replaced at the earliest, with a listref
		 $set_cache = 1;
	***REMOVED***

	  my $has_mi = 0; # set to 0 on the first node we see with 2 parents!
	  # First, just figure out what's in the tree.
	  my %last_child = ($_[0] => 1***REMOVED*** # as if already seen

	  my @tree_nodes;
	***REMOVED***
		 my $current;
		 my @in_stack = ($_[0]***REMOVED***
		 while(@in_stack) {
			next unless
			 defined($current = shift @in_stack)
			 && ref($current) # sanity
			 && ref($current->{'PARENTS'} || 0) # sanity
			;

			push @tree_nodes, $current;

			$has_mi = 1 if @{$current->{'PARENTS'}} > 1;
			unshift
			  @in_stack,
			  map {
				 if(exists $last_child{$_}) { # seen before!
					$last_child{$_} = $current;
					(***REMOVED*** # seen -- don't re-explore
				 } else { # first time seen
					$last_child{$_} = $current;
					$_; # first time seen -- explore now
				 }
			***REMOVED***
			  @{$current->{'PARENTS'}}
			;
		 }

		 # If there was no MI, then that first scan was sufficient.
		 unless($has_mi) {
			$_[0]{'ISA_CACHE'} = \@tree_nodes if $set_cache;
			return @tree_nodes;
		 }

		 # Otherwise, toss this list and rescan, consulting %last_child
	***REMOVED***

	  my @out;
	***REMOVED***
		 my $current;
		 my @in_stack = ($_[0]***REMOVED***
		 while(@in_stack) {
			next unless defined($current = shift @in_stack) && ref($current***REMOVED***
			push @out, $current; # finally.
			unshift
			  @in_stack,
			  grep(
				 (
					defined($_) # sanity
					&& ref($_)  # sanity
					&& $last_child{$_} eq $current,
				 ),
				 # I'm lastborn (or onlyborn) of this parent
				 # so it's OK to explore now
				 @{$current->{'PARENTS'}}
			  )
			 if ref($current->{'PARENTS'} || 0) # sanity
			;
		 }

		 unless(scalar(@out) == scalar(keys(%last_child))) {
			# the counts should be equal
			my %good_ones;
			@good_ones{@out} = (***REMOVED***
			croak
			  "ISA tree for " .
			  ($_[0]{'NAME'} || $_[0]) .
			  " is apparently cyclic, probably involving the nodes " .
			  nodelist( grep { ref($_) && !exists $good_ones{$_} }
				 values(%last_child) )
			  . "\n";
		 }
	***REMOVED***

	  $_[0]{'ISA_CACHE'} = \@out if $set_cache;
	  return @out;
	}

	sub Class::Classless::X::can { # NOT like UNIVERSAL::can ...
	  my($it, $m) = @_[0,1];
	  return undef unless ref $it;

	  croak "undef is not a valid method name"       unless defined($m***REMOVED***
	  croak "null-string is not a valid method name" unless length($m***REMOVED***

	  foreach my $o (&Class::Classless::X::ISA_TREE($it)) {
		 return 1
		  if  ref($o->{'METHODS'} || 0)   # sanity
			&& exists $o->{'METHODS'}{$m***REMOVED***
	***REMOVED***

	  return 0;
	}

	sub Class::Classless::X::isa { # Like UNIVERSAL::isa
	  return unless ref($_[0]) && ref($_[1]***REMOVED***
	  return scalar(grep {$_ eq $_[1]} &Class::Classless::X::ISA_TREE($_[0])***REMOVED*** 
	}

	sub nodelist { join ', ', map { "" . ($_->{'NAME'} || $_) . ""} @_ }

	@Class::Classless::ISA = (***REMOVED***
	sub Class::Classless::CALLSTATE::found_name { $_[0][0] }
		#  the method name called and found
	sub Class::Classless::CALLSTATE::found_depth { $_[0][1] }
		#  my depth in the lineage
	sub Class::Classless::CALLSTATE::lineage { @{$_[0][2]} }
		#  my lineage
	sub Class::Classless::CALLSTATE::target { $_[0][2][  0          ] }
		#  the object that's the target -- same as $_[0] for the method called
	sub Class::Classless::CALLSTATE::home ***REMOVED*** $_[0][2][  $_[0][1]   ] }
		#  the object I was found in
	sub Class::Classless::CALLSTATE::sub_found {
	  $_[0][2][  $_[0][1]   ]{'METHODS'}{ $_[0][0] }
	}  #  the routine called

	sub Class::Classless::CALLSTATE::no_fail        ***REMOVED***  $_[0][3]       ***REMOVED***
	sub Class::Classless::CALLSTATE::set_no_fail_true {  $_[0][3] = 1   ***REMOVED***
	sub Class::Classless::CALLSTATE::set_fail_false ***REMOVED***  $_[0][3] = 0   ***REMOVED***
	sub Class::Classless::CALLSTATE::set_fail_undef ***REMOVED***  $_[0][3] = undef }

	sub Class::Classless::CALLSTATE::via_next       ***REMOVED***  $_[0][4] }

	sub Class::Classless::CALLSTATE::NEXT {
	  my $cs = shift @_;
	  my $m  = shift @_; # which may be (or come out) undef...
	  $m = $cs->[0] unless defined $m; #  the method name called and found

	  ($cs->[2][0])->$m(
		 bless( \$cs, 'Class::Classless::CALLSTATE::SHIMMY' ),
		 @_
	  ***REMOVED***
	}

***REMOVED***
1

# Credits & Thanks
# ================
# chanact.pl for irssi 0.8.2 by bd@bc-bd.org
# ` inspired by chanlist.pl by 'cumol@hammerhart.de'
# ` veli@piipiip.net   /window_alias code
# ` qrczak@knm.org.pl  chanact_abbreviate_names
# ` qerub@home.se      Extra chanact_show_mode and chanact_chop_status
# ` Timo Sirainen, Wouter Coekaerts, Jean-Yves Lefort
#
# buu, fxn, Somni, Khisanth, integral, tybalt89
# ` for perl help and the ir_* functions
# Valentin 'senneth' Batz ( vb@g-23.org )
# ` for the pointer to grep.pl and ir_strip_codes
# OnetrixNET technology networks for the debian environment
# Monkey-Pirate.com / Spaceman Spiff for the webspace
# anti network for the webspace

# Changelog
# =========
# 0.7e
# - remove screen support and replace it with fifo support
# - add double-width support to the shortener
# - correct documentation regarding $T vs. display_header
# - add missing refresh for window item changed (thanks vague)
# - add visible windows
# - add exemptions for active window
# - workaround for hiding the window changes from trackbar
# - hack to force 16colors in screen mode
# - remember last window (reported by earthnative)
#
# 0.6d+
# - headers
# - fixed regression bug /exec -interactive
#
# 0.6ca+
# - add screen support (from nicklist.pl)
# - rename to adv_windowlist.pl (advanced window list) since it isn't just a
#   window list status bar (wlstat) anymore
# - names can now have a max length and window names can be used
# - fixed a bug with block display in screen mode and statusbar mode
# - added space handling to ir_fe and removed it again
# - now handling formats on my own
# - started to work on $tag display
# - added warning about missing sb_act_none abstract leading to
# - display*active settings
# - added warning about the bug in awl_display_(no)key_active settings
# - mouse hack
#
# 0.5d
# - add setting to also hide the last statusbar if empty (awl_all_disable)
# - reverted to old utf8 code to also calculate broken utf8 length correctly
# - simplified dealing with statusbars in wlreset
# - added a little tweak for the renamed term_type somewhere after Irssi 0.8.9
# - fixed bug in handling channel #$$
# - typo on line 200 spotted by f0rked
# - reset background colour at the beginning of an entry
#
# 0.4d
# - fixed order of disabling statusbars
# - several attempts at special chars, without any real success
#   and much more weird new bugs caused by this
# - setting to specify sort order
# - reduced timeout values
# - added awl_hide_data for Geert Hauwaerts ( geert@irssi.org ) :)
# - make it so the dynamic sub is actually deleted
# - fix a bug with removing of the last separator
# - take into consideration parse_special
#
# 0.3b
# - automatically kill old statusbars
# - reset on /reload
# - position/placement settings
#
# 0.2
# - automated retrieval of key bindings (thanks grep.pl authors)
# - improved removing of statusbars
# - got rid of status chop
#
# 0.1
# - rewritten to suit my needs
# - Based on chanact.pl which was apparently based on lightbar.c and
#   nicklist.pl with various other ideas from random scripts.
