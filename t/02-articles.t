#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Mojo::ByteStream 'b';

use FindBin '$Bin';
use lib "$Bin/../lib";

use Bootylite;

# build object
my $dir = "$Bin/articles";
my $b   = Bootylite->new(articles_dir => $dir);
isa_ok($b, 'Bootylite', 'constructor return value');
is_deeply($b, {articles_dir => $dir}, 'right structure');

# build articles
my @fns = sort glob("$dir/*.md");
my @articles = @{$b->articles};
is(scalar(@articles), scalar(@fns), 'found '.@fns.' articles');
foreach my $i (0 .. $#articles) {
    isa_ok($articles[$i], 'Bootylite::Article', 'article');
    is($articles[$i]->filename, $fns[$i], 'right filename');
}

# get article by url
my $a = $b->get_article('test_that_shit2');
ok(defined($a), 'article found by url');
isa_ok($a, 'Bootylite::Article', 'found article');
is($a->url, 'test_that_shit2', 'found the right article');
is($a->content, "\nfoo\n", 'right content');

# caching
$a      = $b->articles->[1];
my $url = $a->url;
my $fn  = $a->filename;
my $raw = $a->raw_content;
rename $fn, "$fn.bak" or die $!;
is($b->get_article($url)->raw_content, $raw, "$url is still in cache");
$b->refresh;
is($b->get_article($url), undef, "$url is gone");
rename "$fn.bak", $fn or die $!;
is($b->get_article($url), undef, "$url is still gone");
$b->refresh;
is($b->get_article($url)->raw_content, $raw, "$url is back");

# tagcloud
is_deeply($b->get_tags, {foo => 2, bar => 1, baz => 2}, 'right tag cloud');

# get articles by tag
my @foo = $b->get_articles_by_tag('foo');
my @bar = $b->get_articles_by_tag('bar');
my @baz = $b->get_articles_by_tag('baz');
my @gay = $b->get_articles_by_tag('gay');
sub urls { [ map { $_->url } @_ ] };
is_deeply( urls(@foo), [qw(test_that_shit1 test_that_shit2)], 'right articles');
is_deeply( urls(@bar), [qw(test_that_shit1)], 'right articles');
is_deeply( urls(@baz), [qw(test_that_shit2 test_that_shit3)], 'right articles');
is(scalar(@gay), 0, 'no articles for the gay tag');

done_testing;

__END__