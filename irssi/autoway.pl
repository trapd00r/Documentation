use warnings;
use strict;

use Irssi ();

our $VERSION = '0.14';
our %IRSSI = (
	authors => 'mauke',
	name => 'autoway',
);

sub act_event () { 'gui key pressed' }

our $away = 'init';
our $activity = time;

Irssi::settings_add_time($IRSSI{name}, "$IRSSI{name}_timeout", '23m');
Irssi::settings_add_str($IRSSI{name}, "$IRSSI{name}_reason", 'zZzZ');

sub record_activity {
	my ($key) = @_;
	#Irssi::print ">activity=[$key]";
	$activity = time;
	$key == ord "\n" or return;
	Irssi::timeout_add_once(100, \&come_back, undef) if $away;
}

sub come_back_1 {
	my ($server) = @_;
	#Irssi::print "coming back: $server->{chatnet} ($server->{address}:$server->{port})";
	if ($server->{usermode_away}) {
		$server->command('away -one');
	}
}

sub come_back {
	# Irssi::print "coming back... [state=$away]";
	return unless $away;
	# Irssi::print "sending away. commands";
	for my $server (Irssi::servers()) {
		come_back_1 $server;
	}
	$away = 0;
	# Irssi::print "restarting timer";
	start_timer();
}

sub go_away_1 {
	my ($server) = @_;
	#Irssi::print "going away: $server->{chatnet} ($server->{address}:$server->{port})";
	unless ($server->{usermode_away}) {
		$server->command('away -one ' . Irssi::settings_get_str("$IRSSI{name}_reason"));
	}
}

sub go_away {
	# Irssi::print "going away... [state=$away]";
	return if $away;
	$away = 'gone';
	# Irssi::print "sending away commands";
	for my $server (Irssi::servers()) {
		go_away_1 $server;
	}
}

our $timer_id;

sub timer {
	my $tsec = Irssi::settings_get_time("$IRSSI{name}_timeout") / 1000;
	my $diff = $tsec - (time - $activity);
	# Irssi::print "ding! time since last activity: " . ((time - $activity) / 60) . "m";
	if ($diff <= 0) {
		$timer_id = undef;
		go_away();
	} else {
		# Irssi::print "scheduling recheck in " . ($diff / 60) . "m";
		$timer_id = Irssi::timeout_add_once(
			$diff * 1000,
			\&timer,
			undef
		);
	}
}

sub start_timer {
	# Irssi::print "whoa, removing $timer_id" if defined $timer_id;
	Irssi::timeout_remove($timer_id) if defined $timer_id;
	# Irssi::print "adding timer";
	$timer_id = Irssi::timeout_add_once(
		Irssi::settings_get_time("$IRSSI{name}_timeout"),
		\&timer,
		undef
	);
}

sub wibble {
	my ($server) = @_;
	if ($away) {
		go_away_1 $server;
	} else {
		come_back_1 $server;
	}
}

Irssi::signal_add_last('server connected' => \&wibble);
#Irssi::signal_add('away mode changed' => \&wibble);

Irssi::signal_add(act_event, \&record_activity);
come_back;
