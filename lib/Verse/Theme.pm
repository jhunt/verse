package Verse::Theme;

use Verse;
use Verse::Object::Blog;
use Verse::Object::Page;
use Template;

use base Exporter;
our @EXPORT = qw/
	exist copy dir
	template render
	blog page
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
	die "`$cmd` failed\n", unless $? == 0;
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
	if (ref($obj) and UNIVERSAL::can($obj, 'permalink')) {
		$attrs{permalink} = $obj->permalink;
		$obj = $obj->vars;
	}
	$obj->{site} = verse->{site};

	my $path = path($opt{at}, %attrs);
	print STDERR "[render] $opt{using} :: $path\n";

	template->process($opt{using}, $obj, $path)
		or die "template failed: ".template->error;
}

sub blog { return Verse::Object::Blog; }
sub page { return Verse::Object::Page; }

1;
