package Verse::Sitemap;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/
	sitemap_add
	sitemap_generate
/;

use URI;

our @URLS = ();

sub sitemap_add
{
	my (%params) = @_;
	# Expected params: loc, lastmod, priority, changefreq, images
	push @URLS, \%params;
}

sub sitemap_generate
{
	my ($output_path, $filter_sub) = @_;
	$filter_sub = $filter_sub or sub { 1 };

	my $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	$xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"' . "\n";
	$xml .= '        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">' . "\n";

	for my $url (@URLS) {
		next unless $filter_sub->(URI->new($url->{loc}));
		$xml .= '  <url>' . "\n";
		$xml .= '    <loc>' . _xml_escape($url->{loc}) . '</loc>' . "\n";
		$xml .= '    <lastmod>' . $url->{lastmod} . '</lastmod>' . "\n" if $url->{lastmod};
		$xml .= '    <priority>' . $url->{priority} . '</priority>' . "\n" if defined $url->{priority};
		$xml .= '    <changefreq>' . $url->{changefreq} . '</changefreq>' . "\n" if $url->{changefreq};

		if ($url->{images} && ref($url->{images}) eq 'ARRAY') {
			for my $img (@{$url->{images}}) {
				$xml .= '    <image:image>' . "\n";
				$xml .= '      <image:loc>' . _xml_escape($img) . '</image:loc>' . "\n";
				$xml .= '    </image:image>' . "\n";
			}
		}

		$xml .= '  </url>' . "\n";
	}

	$xml .= '</urlset>' . "\n";

	# Write sitemap file
	open my $fh, ">", $output_path
		or die "Failed to write sitemap to $output_path: $!\n";
	binmode $fh, ':utf8';
	print $fh $xml;
	close $fh;

	# Clear URLs for next build
	@URLS = ();
}

sub _xml_escape
{
	my ($str) = @_;
	return '' unless defined $str;
	$str =~ s/&/&amp;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s/"/&quot;/g;
	$str =~ s/'/&apos;/g;
	return $str;
}

1;

=head1 NAME

Verse::Sitemap - Sitemap Generation for Verse

=head1 SYNOPSIS

    use Verse::Sitemap;

    # During rendering, add URLs to the sitemap
    sitemap_add(
        loc        => 'https://example.com/page.html',
        lastmod    => '2024-03-15',
        priority   => 0.8,
        changefreq => 'weekly',
        images     => ['/images/hero.jpg'],
    );

    # At the end of the build, generate sitemap.xml
    sitemap_generate(path("{site}/sitemap.xml"));

=head1 DESCRIPTION

Verse::Sitemap provides automatic sitemap.xml generation with support
for priority, changefreq, lastmod, and image sitemaps.

=head1 FUNCTIONS

=head2 sitemap_add(%params)

Add a URL to the sitemap. Parameters:

=over

=item B<loc> (required)

The full URL of the page.

=item B<lastmod>

Last modification date in YYYY-MM-DD format.

=item B<priority>

Priority between 0.0 and 1.0.

=item B<changefreq>

How frequently the page changes: always, hourly, daily, weekly,
monthly, yearly, never.

=item B<images>

Arrayref of image URLs for this page.

=back

=head2 sitemap_generate($output_path)

Generate the sitemap.xml file at the given path using all URLs
that were added via sitemap_add(). Clears the URL list after
generation.

=head1 AUTHOR

Claude <claude@localhost>

=cut
