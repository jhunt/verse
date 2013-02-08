package Verse;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/
	rhyme
	verse
/;

use YAML qw/LoadFile/;
use Hash::Merge qw/merge/;

our $VERSION = '0.5';

our $ROOT = $ENV{PWD};

my $CONFIG = undef;

sub qualify_path
{
	my ($path) = @_;
	return unless $path;
	return $path if substr($path, 0, 1) eq '/';
	return "$ENV{PWD}/$path";
}

sub verse()
{
	return $CONFIG if $CONFIG;

	-d "$ROOT/.verse"
		or die "Verse boot failed: No .verse directory in $ROOT/\n";
	-f "$ROOT/.verse/site.yml"

		or die "Verse boot failed: No site.yml in $ROOT/.verse\n";

	$CONFIG = LoadFile("$ROOT/.verse/site.yml")
		or die "Verse boot failure: $ROOT\n";

	$CONFIG = merge($CONFIG, {
		paths => {
			site => 'htdocs',
			root => '.verse',
			data => '.verse/data',
		},
		site => {
			theme => 'default',
		},
	});

	for (keys %{$CONFIG->{paths}}) {
		$CONFIG->{paths}{$_} = qualify_path($CONFIG->{paths}{$_});
	}

	$CONFIG->{paths}{theme} = $CONFIG->{paths}{root}."/theme/".$CONFIG->{site}{theme};

	return $CONFIG;
}

sub rhyme
{
	my $v = verse;

	print "\x1b[38;5;4mloading.\n\x1b[38;5;2m";
	print <<'EOF';


  ##     ## ######## ########   ######  ########
  ##     ## ##       ##     ## ##    ## ##
  ##     ## ##       ##     ## ##       ##
  ##     ## ######   ########   ######  ######
   ##   ##  ##       ##   ##         ## ##
    ## ##   ##       ##    ##  ##    ## ##
     ###    ######## ##     ##  ######  ########


EOF
	print <<EOF
\x1b[0m
ROOT:   $v->{paths}{root}
SITE:   $v->{paths}{site}
DATA:   $v->{paths}{data}
THEME:  $v->{site}{theme}


EOF
}

1;

=head1 NAME

Verse - Static Blogging

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
