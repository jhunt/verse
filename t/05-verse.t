#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Output;
use lib 'lib';
use lib 'ext';

BEGIN { use_ok 'Verse' or BAIL_OUT "Failed to `use Verse`" }


{ # verse config function
	if (exists $ENV{PWD}) {
		is($Verse::ROOT, $ENV{PWD},
			"Verse defaults to PWD for ROOT");
	}

	$Verse::ROOT = '/no/such/path';
	ok(!-d $Verse::ROOT,
		"/no/such/path/.verse should not exist");
	throws_ok { verse } qr/site\.yml: No such file/,
		'verse fails if .verse directory does not exist';

	$Verse::ROOT = 't/data/root/empty';
	throws_ok { verse } qr/site\.yml: No such file/,
		'verse fails if it cannot find .verse/site.yml';

	$Verse::ROOT = 't/data/root/badyaml';
	throws_ok { verse } qr/Failed to parse .verse\/site\.yml/,
		'verse fails if it cannot parse .verse/site.yml';

}

{ # parse_config_string helper method (INTERNAL)
	my $config;

	$Verse::ROOT = '/u/sites/example.com';

	$config = <<EOF;
site:
  title: Default Settings
EOF
	cmp_deeply(Verse::parse_config_string($config), {
			site => {
				title => 'Default Settings',
				theme => 'default', # DEFAULT
			},
			paths => { # ALL DEFAULT
				site  => '/u/sites/example.com/htdocs',
				root  => '/u/sites/example.com/.verse',
				data  => '/u/sites/example.com/.verse/data',
				theme => '/u/sites/example.com/.verse/theme/default', # AUTO-SET
			}
		}, "Verse provides sane defaults");

	$config = <<EOF;
site:
  title: Overrides
  url:   http://www.example.com
  theme: override
paths:
  site: site_root
  root: .web
  data: site_data
  theme: /srv/www/themes/override
EOF
	cmp_deeply(Verse::parse_config_string($config), {
			site => {
				title => 'Overrides',
				url   => 'http://www.example.com',
				theme => 'override',
			},
			paths => {
				site  => '/u/sites/example.com/site_root',
				root  => '/u/sites/example.com/.web',
				data  => '/u/sites/example.com/site_data',
				theme => '/srv/www/themes/override',
			}
		}, "Verse allows full override of defaults");
}

{ # rhyme - prints a bunch of stuff to stdout
	$Verse::ROOT = 't/data/root/good';

	cmp_deeply(verse, verse,
		"Verse memoizes; two calls should return the same values");

	my $expect = <<EOF;
\x1b[38;5;4mloading.
\x1b[38;5;2m

  ##     ## ######## ########   ######  ########
  ##     ## ##       ##     ## ##    ## ##
  ##     ## ##       ##     ## ##       ##
  ##     ## ######   ########   ######  ######
   ##   ##  ##       ##   ##         ## ##
    ## ##   ##       ##    ##  ##    ## ##
     ###    ######## ##     ##  ######  ########


\x1b[0m
ROOT:   /u/sites/example.com/verse
SITE:   /u/sites/example.com/htdocs
DATA:   /u/sites/example.com/data
THEME:  default


EOF
	stdout_is { rhyme } $expect,
		"rhyme prints diagnostic boot messages";
}

done_testing;
