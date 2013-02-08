package Verse::Tools;

use Verse;

use base 'Exporter';
our @EXPORT = qw/
	render
/;

sub render
{
	my $theme = verse->{paths}{theme}.'/render';
	die "Failed to find theme file: $theme\n"
		unless -x $theme;

	eval { require $theme } or die "$@\n";
}

1;
