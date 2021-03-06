#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 'lib';
use lib 'ext';

BEGIN { use_ok 'Verse::Template'
		or BAIL_OUT "Could not `use Verse::Template`" }

sub _parse {
	my ($src) = @_;
	Verse::Template::_parse(Verse::Template::_tokenize($src)),
}
sub _do {
	my ($src, $vars) = @_;
	Verse::Template::_evaluate(_parse($src), $vars || {});
}

my $src;

########################################################
# 1
cmp_deeply([Verse::Template::_i2pf({
	token  => [Verse::Template::T_NUMBER, '1'],
	tokens => [[Verse::Template::T_CLOSE]],
})],
	[[Verse::Template::T_NUMBER, '1']],
	"infix to postfix should handle a single value");

########################################################
# x == 1 or y == 2
cmp_deeply([Verse::Template::_i2pf({
	token  => [Verse::Template::T_IDENT, 'x'],
	tokens => [[Verse::Template::T_EQ],
	           [Verse::Template::T_NUMBER, '1'],
	           [Verse::Template::T_OR],
	           [Verse::Template::T_IDENT, 'y'],
	           [Verse::Template::T_EQ],
	           [Verse::Template::T_NUMBER, '2'],
	           [Verse::Template::T_CLOSE]],
})],
	[[Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_NUMBER, '1'],
	 [Verse::Template::T_EQ],
	 [Verse::Template::T_IDENT, 'y'],
	 [Verse::Template::T_NUMBER, '2'],
	 [Verse::Template::T_EQ],
	 [Verse::Template::T_OR]],
	"infix to postfix should handle precedence levels");

########################################################
# !x
cmp_deeply([Verse::Template::_i2pf({
	token  => [Verse::Template::T_NOT],
	tokens => [[Verse::Template::T_IDENT, 'x'],
	           [Verse::Template::T_CLOSE]],
})],
	[[Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_NOT]],
	"infix to postfix should handle unary operators");

########################################################
# x == 1 or (y == 2 and z == 3)
cmp_deeply([Verse::Template::_i2pf({
	token  => [Verse::Template::T_IDENT, 'x'],
	tokens => [[Verse::Template::T_EQ],
	           [Verse::Template::T_NUMBER, '1'],
	           [Verse::Template::T_OR],
	           [Verse::Template::T_OPAR],
	           [Verse::Template::T_IDENT, 'y'],
	           [Verse::Template::T_EQ],
	           [Verse::Template::T_NUMBER, '2'],
	           [Verse::Template::T_AND],
	           [Verse::Template::T_IDENT, 'z'],
	           [Verse::Template::T_EQ],
	           [Verse::Template::T_NUMBER, '3'],
	           [Verse::Template::T_CPAR],
	           [Verse::Template::T_CLOSE]],
})],
	[[Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_NUMBER, '1'],
	 [Verse::Template::T_EQ],
	 [Verse::Template::T_IDENT, 'y'],
	 [Verse::Template::T_NUMBER, '2'],
	 [Verse::Template::T_EQ],
	 [Verse::Template::T_IDENT, 'z'],
	 [Verse::Template::T_NUMBER, '3'],
	 [Verse::Template::T_EQ],
	 [Verse::Template::T_AND],
	 [Verse::Template::T_OR]],
	"infix to postfix should handle precedence levels");

########################################################
cmp_deeply(Verse::Template::_tokenize(''),
	[[Verse::Template::T_EOT]],
	"tokenizing the empty template (should have no ops)");

cmp_deeply(_parse(''),
	['SEQ'], "parsing the empty template (should have no ops)");

is(_do(''), '', "evaluating the template");

########################################################
$src = 'a single text block';
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT,$src],
	 [Verse::Template::T_EOT]],
	"tokenizing a single text block, with no [% ... %] ops");

cmp_deeply(_parse($src),
	['SEQ', ['ECHO', $src]],
	"parsing a single block, with no [% ... %] ops");

is(_do($src),
	'a single text block',
	"evaluating a single block, with no [% ... %] ops");

########################################################
$src = 'a [% type %] block';
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT, 'a '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'type'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, ' block'],
	 [Verse::Template::T_EOT]],
	"tokenizing a composite TEXT - OP - TEXT template");
cmp_deeply(_parse($src),
	['SEQ', ['ECHO', 'a '],
	        ['DEREF', 'type'],
	        ['ECHO', ' block']],
	"parsing a composite TEXT - OP - TEXT template");
is(_do($src, { type => 'verse' }),
	'a verse block',
	"evaluating a composite TEXT - OP - TEXT template");

########################################################
$src = 'a [%- type -%] block';
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT, 'a'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'type'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'block'],
	 [Verse::Template::T_EOT]],
	"tokenizing a composite TEXT - OP - TEXT template (trim)");
cmp_deeply(_parse($src),
	['SEQ', ['ECHO', 'a'],
	        ['DEREF', 'type'],
	        ['ECHO', 'block']],
	"parsing a composite TEXT - OP - TEXT template (trim)");
is(_do($src, { type => 'nono' }),
	'anonoblock',
	"evaluating a composite TEXT - OP - TEXT template (trim)");

########################################################
$src = "[% a.dotted.var %]";
is(_do($src, { a => { dotted => { var => 'wins' } } }),
	'wins',
	"var deref can handle dotted variables");

########################################################
$src = "[% x = 1 %][% x %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_ASSIGN],
	 [Verse::Template::T_NUMBER, '1'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing assignment");
cmp_deeply(_parse($src),
	['SEQ', ['LET', 'x', ['value', 1]],
	        ['DEREF', 'x']],
	"parsing assignment");
is(_do($src, { x => 42 }), "1",
	"evaluating assignment + echo (pre-existing binding)");
is(_do($src), "1",
	"evaluating assignment + echo (no binding)");

########################################################
$src = "[% n = 1 %][% n %], [% n = n + 1 %][% n %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'n'],
	 [Verse::Template::T_ASSIGN],
	 [Verse::Template::T_NUMBER, '1'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'n'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, ', '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'n'],
	 [Verse::Template::T_ASSIGN],
	 [Verse::Template::T_IDENT, 'n'],
	 [Verse::Template::T_ADD],
	 [Verse::Template::T_NUMBER, '1'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'n'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing re-assignment");

########################################################
$src = "v: [% if set %]is not [% end %]unset";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT, 'v: '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_IDENT, 'set'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'is not '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'unset'],
	 [Verse::Template::T_EOT]],
	"tokenizing a simple if-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['ECHO', 'v: '],
	        ['IF', ['ref', 'set'],
	               ['SEQ', ['ECHO', 'is not ']],
	               ['NOOP']],
	        ['ECHO', 'unset']],
	"parsing a simple if-conditional");
is(_do($src, { set => 1 }),
	'v: is not unset',
	"evaluating a simple if-conditional (consequent)");
is(_do($src, {}),
	'v: unset',
	"evaluating a simple if-conditional (alternate)");
is(_do($src, { set => 0 }),
	'v: unset',
	"evaluating a simple if-conditional (alternate, explicit false value)");
is(_do($src, { set => undef }),
	'v: unset',
	"evaluating a simple if-conditional (alternate, explicit undef value)");

$src = "[% if !set %]x[% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_NOT],
	 [Verse::Template::T_IDENT, 'set'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'x'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing a negated if-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['IF', ['not', ['ref', 'set']],
	               ['SEQ', ['ECHO', 'x']],
	               ['NOOP']]],
	"parsing a negated if-conditional");

########################################################
$src = "[% if yes %]no[% else %]yes[% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_IDENT, 'yes'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'no'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_ELSE],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'yes'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing an if-else-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['IF', ['ref', 'yes'],
	               ['SEQ', ['ECHO', 'no']],
	               ['SEQ', ['ECHO', 'yes' ]]]],
	"parsing a if-else-conditional");
is(_do($src, { yes => 1 }),
	'no',
	"evaluating a if-else-conditional (consequent)");
is(_do($src, { yes => 0 }),
	'yes',
	"evaluating a if-else-conditional (alternate)");

########################################################
$src = "[% if yes %]sure[% else if no %]nah[% else %]maybe[% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_IDENT, 'yes'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'sure'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_ELSE],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_IDENT, 'no'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'nah'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_ELSE],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'maybe'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing an if-else-if-else-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['IF', ['ref', 'yes'],
	               ['SEQ', ['ECHO', 'sure']],
	               ['IF', ['ref', 'no'],
	                      ['SEQ', ['ECHO', 'nah' ]],
	                      ['SEQ', ['ECHO', 'maybe' ]]]]],
	"parsing a if-else-if-else-conditional");
is(_do($src, { yes => 1 }),
	'sure',
	"evaluating a if-else-if-else-conditional (first consequent)");
is(_do($src, { no => 1 }),
	'nah',
	"evaluating a if-else-if-else-conditional (second consequent)");
is(_do($src, {}),
	'maybe',
	"evaluating a if-else-if-else-conditional (alternate)");

########################################################
$src = "[% if yes %]sure[% else unless no %]maybe[% else %]nah[% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_IF],
	 [Verse::Template::T_IDENT, 'yes'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'sure'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_ELSE],
	 [Verse::Template::T_UNLESS],
	 [Verse::Template::T_IDENT, 'no'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'maybe'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_ELSE],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'nah'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing an if-else-unless-else-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['IF', ['ref', 'yes'],
	               ['SEQ', ['ECHO', 'sure']],
	               ['IF', ['not', ['ref', 'no']],
	                      ['SEQ', ['ECHO', 'maybe' ]],
	                      ['SEQ', ['ECHO', 'nah' ]]]]],
	"parsing a if-else-unless-else-conditional");
is(_do($src, { yes => 1 }),
	'sure',
	"evaluating a if-else-unless-else-conditional (first consequent)");
is(_do($src, { no => 1 }),
	'nah',
	"evaluating a if-else-unless-else-conditional (second consequent)");
is(_do($src, {}),
	'maybe',
	"evaluating a if-else-unless-else-conditional (alternate)");

########################################################
$src = "v: [% unless set %]not [% end %]set";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT, 'v: '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_UNLESS],
	 [Verse::Template::T_IDENT, 'set'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'not '],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, 'set'],
	 [Verse::Template::T_EOT]],
	"tokenizing a simple unless-conditional");
cmp_deeply(_parse($src),
	['SEQ', ['ECHO', 'v: '],
	        ['IF', ['not', ['ref', 'set']],
	               ['SEQ', ['ECHO', 'not ']],
	               ['NOOP']],
	        ['ECHO', 'set']],
	"parsing a simple unless-conditional");
is(_do($src, { set => 0 }),
	'v: not set',
	"evaluating a simple unless-conditional (consequent)");
is(_do($src, { set => 1 }),
	'v: set',
	"evaluating a simple unless-conditional (alternate)");

########################################################
$src = "things:[% for x in list %] ([% x %])[% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_TEXT, 'things:'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_FOR],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_IN],
	 [Verse::Template::T_IDENT, 'list'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, ' ('],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, ')'],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing a simple for-loop");
cmp_deeply(_parse($src),
	['SEQ', ['ECHO', 'things:'],
	        ['FOR', 'x', 'list',
	          ['SEQ', ['ECHO', ' ('],
	                  ['DEREF', 'x'],
	                  ['ECHO', ')']]]],
	"parsing a simple for-loop");
is(_do($src, { list => [1,2,3]}),
	'things: (1) (2) (3)',
	"evaluating a simple for-loop");

########################################################
$src = "[% for x in l %][% for y in l %][% x %][% y %];[% end %][% end %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_FOR],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_IN],
	 [Verse::Template::T_IDENT, 'l'],
	 [Verse::Template::T_CLOSE],

	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_FOR],
	 [Verse::Template::T_IDENT, 'y'],
	 [Verse::Template::T_IN],
	 [Verse::Template::T_IDENT, 'l'],
	 [Verse::Template::T_CLOSE],

	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'x'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_IDENT, 'y'],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_TEXT, ';'],

	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],

	 [Verse::Template::T_OPEN],
	 [Verse::Template::T_END],
	 [Verse::Template::T_CLOSE],

	 [Verse::Template::T_EOT]],
	"tokenizing a nested for-loop");
cmp_deeply(_parse($src),
	['SEQ', ['FOR', 'x', 'l',
	          ['SEQ', ['FOR', 'y', 'l',
	                    ['SEQ', ['DEREF', 'x'],
	                            ['DEREF', 'y'],
	                            ['ECHO', ';']]]]]],
	"parsing a nested for-loop");
is(_do($src, { l => [1,2,3]}),
	'11;12;13;21;22;23;31;32;33;',
	"evaluating a nested for-loop");

########################################################
$src = "[% format('test %s', 'value') %]";
cmp_deeply(Verse::Template::_tokenize($src),
	[[Verse::Template::T_OPEN],
	 [Verse::Template::T_FUNCALL, 'format'],
	 [Verse::Template::T_STRING, 'test %s'],
	 [Verse::Template::T_COMMA],
	 [Verse::Template::T_STRING, 'value'],
	 [Verse::Template::T_CPAR],
	 [Verse::Template::T_CLOSE],
	 [Verse::Template::T_EOT]],
	"tokenizing a function application");
cmp_deeply(_parse($src),
	['SEQ', ['APPLY', 'format',
	                     ['value', 'test %s'],
	                     ['value', 'value']]],
	"parsing a function application");
is(_do($src), 'test value',
	"evaluating a function application");

########################################################
$src = "[% if v %]ok[% end %]";
is(_do($src, { v => 'test' }),
	'ok', "expression language understands string truthiness");
is(_do($src, { v => 0 }),
	'', "expression language understands string truthiness (negative)");

$src = "[% if !v %]ok[% end %]";
is(_do($src, { v => 'test' }),
	'', "expression language understands string falsiness");
is(_do($src, { v => 0 }),
	'ok', "expression language understands string falsiness (negative)");

$src = "[% if v == 'test' %]ok[% end %]";
is(_do($src, { v => 'test' }),
	'ok', "expression language understands string equality");
is(_do($src, { v => 'NO' }),
	'', "expression language understands string equality (negative)");

$src = "[% if x == 1 or y == 2 %]ok[% end %]";
is(_do($src, { x => 1 }),
	'ok', "expression language understands compound conditionals");
is(_do($src, { x => 0, y => 2 }),
	'ok', "expression language understands compound conditionals (alt branch)");
is(_do($src, { x => 0, y => 0 }),
	'', "expression language understands compound conditionals (negative)");

$src = "[% if x >= 1 or y <= 2 %]ok[% end %]";
is(_do($src, { x => 1 }),
	'ok', "expression language understands comparison operators");
is(_do($src, { x => 0, y => 0 }),
	'ok', "expression language understands comparison operators (alt branch)");
is(_do($src, { x => 0, y => 10 }),
	'', "expression language understands comparison operators (negative)");

$src = "[% if x == 1 and y == x %]ok[% end %]";
is(_do($src, { x => 1, y => 1 }),
	'ok', "expression language understands compound and-conditionals");
is(_do($src, { x => 1, y => 5 }),
	'', "expression language understands compound and-conditionals (negative)");

$src = "[% if x =~ m/test/ %]ok[% end %]";
is(_do($src, { x => 'a testing string' }),
	'ok', "expression language understands regex matches");
is(_do($src, { x => 'production' }),
	'', "expression language understands regex matches (negative)");

$src = "[% if x !~ m/test/ %]ok[% end %]";
is(_do($src, { x => 'a testing string' }),
	'', "expression language understands regex un-matches");
is(_do($src, { x => 'production' }),
	'ok', "expression language understands regex un-matches (negative)");

$src = "[% for x in list %][% loop.i %]/[% loop.n %]; [% end %]";
is(_do($src, { list => [qw[a b c]] }),
	'0/3; 1/3; 2/3; ', "loop.i / loop.n meta-variables are recognized");

$src = "[% for x in list %]".
         "[% if loop.first %]([% end %]".
         "[% x %]".
         "[% if loop.last %])[% else %],[% end %]".
       "[% end %]";
is(_do($src, { list => [qw[a b c]] }),
	'(a,b,c)', "loop.first / loop.last meta-variables are recognized");

########################################################
is(template(['t/tpl/outer.tt', 't/tpl/page.tt'],
	{ title => 'some title', lang => 'en' }),
	q(<html lang="en">
  <h1>some title</h1>
</html>), "template() should handle nested templates");

done_testing;
