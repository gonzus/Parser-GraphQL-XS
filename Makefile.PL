use 5.008009;
use Config;
use ExtUtils::MakeMaker;
use Alien::libgraphqlparser;

my $linker_flags = $Config{lddlflags} // '';
$linker_flags   .= " ";
# ->libs_static is actually Libs + Libs.private; the out-in-the-wild version
# of libgraphqlparser leaves that empty, while the version built by
# `Alien::libgraphqlparser` puts the static library there.
# So if we are linking against an OS-provided .so, everything works as
# before, but if we are linking against the private version built by
# Alien::libgraphqlparser, we end up statically linking against it,
# since otherwise we would not be able to dlopen() it.
$linker_flags   .= Alien::libgraphqlparser->libs_static;

WriteMakefile(
    NAME           => 'Parser::GraphQL::XS',
    VERSION_FROM   => 'lib/Parser/GraphQL/XS.pm',
    ABSTRACT_FROM  => 'lib/Parser/GraphQL/XS.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.018000,
    CONFIGURE_REQUIRES => {
        'Alien::libgraphqlparser' => 0.01,
    },
    PREREQ_PM      => {
        'XSLoader'     => 0,
    },
    TEST_REQUIRES  => {
        'Data::Dumper' => 0,
        'JSON::XS'     => 0,
        'Path::Tiny'   => 0,
        'Test::More'   => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],
    LDDLFLAGS      => $linker_flags,
    OBJECT         => '$(O_FILES)',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:gonzus/Parser-GraphQL-XS',
                web  => 'https://github.com/gonzus/Parser-GraphQL-XS',
            },
        },
    },
);

# Add options CCFLAGS without overwriting the defaults
package MY;
sub cflags {
    my $self   = shift;
    my $cflags = $self->SUPER::cflags(@_);
    my @cflags = split /\n/, $cflags;

    # turn on a bunch of warning flags
    my @warning_flags_always = qw/
        all
        extra
        declaration-after-statement
        comment
    /;
    $self->{CCFLAGS} .= " -W$_" for @warning_flags_always;
    $self->{CCFLAGS} .= " " . Alien::libgraphqlparser->cflags // '';

    foreach (@cflags) {
        $_ = "CCFLAGS = $self->{CCFLAGS}" if /^CCFLAGS/;
    }
    return $self->{CFLAGS} = join("\n", @cflags) . "\n";
}
