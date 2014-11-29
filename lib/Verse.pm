package Verse;

use strict;
use warnings;
use Carp;

use base 'Exporter';
our @EXPORT = qw/
	rhyme
	verse
/;

use Verse::Utils;
use YAML qw/LoadFile Load/;
use Hash::Merge qw/merge/;

our $VERSION = '0.8.0';

our $ROOT = $ENV{PWD};
our $VDIR = -f "$ROOT/site.yml" ? '.' : '.verse';

sub parse_config_string
{
	my ($yaml) = @_;
	my $cfg = Load($yaml);

	$cfg = merge($cfg, {
		paths => {
			site => 'htdocs',
			root => "$VDIR",
			data => "$VDIR/data",
		},
		site => {
			theme => 'default',
		},
	});
	for (keys %{$cfg->{paths}}) {
		$cfg->{paths}{$_} = vpath($cfg->{paths}{$_});
	}

	$cfg->{paths}{theme} = $cfg->{paths}{root}."/theme/".$cfg->{site}{theme}
		unless exists $cfg->{paths}{theme};

	$cfg;
}

my $CONFIG = undef;

sub verse
{
	$CONFIG = undef if $_[0];
	return $CONFIG if $CONFIG;

	open my $fh, "<", "$ROOT/$VDIR/site.yml"
		or croak "Failed to read $VDIR/site.yml: $!\n";

	eval { $CONFIG = parse_config_string(do { local $/; <$fh> }) }
		or croak "Failed to parse $VDIR/site.yml\n";
	close $fh;

	if ($ENV{VERSE_LOCAL}) {
		$CONFIG->{site}{url} = "file://$ROOT/htdocs";
	}

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

Verse - Static Website Generator

=head1 DESCRIPTION

Verse provides a framework for building websites using Perl's
Template Toolkit, YAML and the filesystem.

=head1 FUNCTIONS

=head2 verse

Return the fully-qualified Verse configuration, based on the
site.yml file found in B<$Verse::ROOT/$Verse::VDIR>.  This configuration
hash will be memoized, so future calls to B<verse> do not incur
the same parsing / normalization overhead.

=head2 rhyme

Print the Verse boot screen, which includes diagnostic messages
about the paths that will be used during the render process.

=head2 parse_config_string($yaml)

Parse the B<$yaml> string as Verse configuration, supplying sane
defaults and resolving paths as appropriate.

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
