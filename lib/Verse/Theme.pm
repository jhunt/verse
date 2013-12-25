package Verse::Theme;

use Carp;
use Verse;
use Verse::Object::Blog;
use Verse::Object::Page;
use Verse::Object::Gallery;
use Verse::Jump;
use File::Find qw/find/;
use Template;

use base Exporter;
our @EXPORT = qw/
	path
	exist copy dir
	template render
	blog page gallery
	jump
	diagrams
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

my %TT = ();
sub template
{
	my ($layout) = @_;

	if (!$layout or $layout ne 'NONE') {
		$layout = path("{theme}/layouts/".($layout || 'site.tt'));
		$layout = path("{theme}/layouts/site.tt") unless -f $layout;
	}
	return $TT{$layout} if $TT{$layout};

	$TT{$layout} = Template->new({
		ENCODING     => "utf8",
		ABSOLUTE     => 1,
		INCLUDE_PATH => path("{theme}/templates"),
		($layout eq 'NONE' ? ()
		                   : (WRAPPER => $layout)),
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

	template($opt{layout})->process($opt{using}, $obj, $path, {binmode => ':utf8'})
		or croak "template failed: ".template->error;
}

sub blog    { Verse::Object::Blog }
sub page    { Verse::Object::Page }
sub gallery { Verse::Object::Gallery }

sub jump
{
	my (%opt) = @_;
	$opt{template} ||= 'redir.tt';
	$opt{root}     ||= 'go';

	my $jump = Verse::Jump->read(path("{root}/jump.yml"));
	for ($jump->resolve(verse->{site}{url})->pairs) {
		my ($local, $remote) = @$_;
		dir "{site}/$opt{root}/$local";
		my $obj = {
			path   => "$opt{root}/$local",
			target => $remote,
		};
		render $obj,
		       layout => 'NONE',
		       using  => $opt{template},
		       at     => "{site}/$opt{root}/$local/index.html";
	}
}

sub diagrams
{
	my (%opt) = @_;
	$opt{source}      = "{root}/data/diag";
	$opt{destination} = "{site}/diag";

	copy $opt{source} if exist $opt{source};

	for my $type (qw/dot twopi circo neato fdp sfdp/) {
		find({
			no_chdir => 1,
			wanted => sub {
				return unless -f and m/\.$type$/;

				my $src = $_;
				s/\.$type$/\.png/;

				print "[run] $type -Tpng $src > $_\n";
				qx($type -Tpng $src > $_);
				unlink $src;
			}
		}, path($opt{destination}));
	}
}

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

=head2 jump(%opts)

Render all redirection / jump pages, as defined in jump.yml in the .verse
root directory.

=head2 diagrams(%opts)

Using graphviz utilities (dot, circo, fdp, neato, etc.), render all diagrams
in {root}/data/diag (or whatever the B<source> option is passed as).  All
resultant files will be PNG images, in {site}/diag.

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
