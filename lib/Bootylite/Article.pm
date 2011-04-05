package Bootylite::Article;

use Mojo::Base -base;
use Mojo::Asset::File;
use File::Spec::Functions 'splitpath';
use Time::Local 'timelocal';
use Mojo::ByteStream 'b';

# note: all this shit is very lazy

# bootylite articles are file system based
has filename    => sub { die 'no file name given' };
has encoding    => 'utf-8';

# inject date and url from filename
sub _inject_filename_data {
    my $self = shift;

    # extract file name
    my (undef, undef, $filename) = splitpath($self->filename);

    # parse
    die 'filename not parseable: ' . $filename unless $filename =~ /^
        (\d\d\d\d)          # year
        -(\d\d)             # month
        -(\d\d)             # day
        (?:-(\d\d)-(\d\d))? # optional: hour and minute
        _(.*)               # url part
        \.[a-z]+            # extension
    $/x;

    # build date and url part
    my $time = timelocal(0, $5 // 0, $4 // 0, $3, $2 - 1, $1);
    my $url  = lc $6;

    # inject and chain
    return $self->time($time)->url($url);
}

# get date or url from filename
has time    => sub { shift->_inject_filename_data->time };
has url     => sub { shift->_inject_filename_data->url };

# slurp that shit
has raw_content => sub {
    my $self = shift;

    # slurp
    my $file    = Mojo::Asset::File->new(path => $self->filename);
    my $encoded = $file->slurp;

    # decode
    return b($encoded)->decode($self->encoding)->to_string;
};

# split content in meta data, teaser, separator and content and inject
sub _inject_content_data {
    my $self = shift;
    my $raw  = $self->raw_content;

    # extract and kill meta data
    my %meta        = ();
    $meta{lc $1}    = $2 while $raw =~ s/^(\w+): (.+)\n+//;

    # arrify tags
    $meta{tags} = [ split /,\s*/ => $meta{tags} // '' ];

    # extract teaser, separator and content
    die 'content unparseable: ' . $raw unless $raw =~ /\A
        (?:                 # optional teaser part
            (.*)            # teaser
            ^\[cut\]        # separator start
            [ \t]*          # separator separator
            ([^\n]+)?       # optional separator text
            \n              # separator end
        )?                  # end of optional teaser part
        (.*)                # content part
    \z/smx;
    
    # build
    my $teaser      = $1;
    my $separator   = $2;
    my $content     = $3;

    # inject and chain
    return $self->meta(\%meta)
                ->teaser($teaser)
                ->separator($separator)
                ->content($content);
}

# extract content data from raw content
has meta        => sub { shift->_inject_content_data->meta };
has teaser      => sub { shift->_inject_content_data->teaser };
has separator   => sub { shift->_inject_content_data->separator };
has content     => sub { shift->_inject_content_data->content };

!! 42;
__END__