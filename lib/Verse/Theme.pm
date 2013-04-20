package Verse::Theme;

use Carp;
use Verse;
use Verse::Object::Blog;
use Verse::Object::Page;
use Verse::Object::Gallery;
use Template;

use base Exporter;
our @EXPORT = qw/
	exist copy dir
	template render
	blog page gallery
/;

sub path
{
	my ($path, %extra) = @_;

	my $SITE  = verse->{paths}{site};
	my $DATA  = verse->{paths}{data};
	my $ROOT  = verse->{paths}{root};
	my $THEME = verse->{paths}{theme};

	$path =~ s/{data}/$DATA/g;
	$path =~ s/{site}/$SITE/g;
	$path =~ s/{root}/$ROOT/g;
	$path =~ s/{theme}/$THEME/g;

	for my $re (keys %extra) {
		$path =~ s/{$re}/$extra{$re}/g;
	}

	return $path;
}

sub run
{
	my ($cmd) = @_;
	print STDERR "[run] $cmd\n";
	system($cmd);
	croak "`$cmd` failed\n", unless $? == 0;
}

sub exist
{
	my ($path) = @_;
	return -e path($path);
}

sub copy
{
	my ($from, $to) = @_;
	$to = "{site}" unless $to;

	$from = path($from);
	$to   = path($to);
	run("cp -a $from $to");
}

sub dir
{
	run("mkdir -p ".path($_)) for @_;
}

my $TT;
sub template
{
	return $TT if $TT;
	$TT = Template->new({
		ENCODING     => "utf-8",
		ABSOLUTE     => 1,
		INCLUDE_PATH => path("{theme}/templates"),
		WRAPPER      => path("{theme}/layouts/site.tt"),
		EVAL_PERL    => 1,
		PRE_CHOMP    => 1,
		POST_CHOMP   => 1,
		TRIM         => 1,
		ANYCASE      => 1,
	});
}

sub render
{
	my ($obj, %opt) = @_;

	my %attrs = ();
	if (ref($obj) and UNIVERSAL::can($obj, 'uuid')) {
		$attrs{permalink} = $obj->uuid;
		$obj = { $obj->type => $obj };
	}
	$obj->{site} = verse->{site};

	my $path = path($opt{at}, %attrs);
	print STDERR "[render] $opt{using} :: $path\n";

	template->process($opt{using}, $obj, $path)
		or croak "template failed: ".template->error;
}

sub blog    { Verse::Object::Blog }
sub page    { Verse::Object::Page }
sub gallery { Verse::Object::Gallery }

1;

=head1 NAME

Verse::Theme - Utilities for Theme Writers

=head1 DESCRIPTION

The Verse::Theme modules defines a set of related functions that
make writing themes for Verse easier.

=head1 FUNCTIONS

=head2 exist($path)

Returns true if the interpolated B<$path> exists.

=head2 copy($from, $to)

Copies files from B<$from> into B<$to>.

=head2 dir(@paths)

Creates a set of directories.

=head2 template()

Returns a Template Toolkit object for use in rendering.

=head2 render($obj_or_vars, as => $path, using => $template)

Renders a template.

=head2 blog()

Shortcut for Verse::Object::Blog

=head2 page()

Shortcut for Verse::Object::Page

=head2 gallery()

Shortcut for Verse::Object::Gallery

=head1 INTERNAL FUNCTIONS

=head2 path($path, %extra)

Replace slugs in $path with the appropriate values.  The following
are recognized by default:

=over

=item B<{root}>

=item B<{data}>

=item B<{site}>

=item B<{theme}>

=back

=head2 run($cmd)

Execute a command, printing helpful diagnostics to standard error.

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
