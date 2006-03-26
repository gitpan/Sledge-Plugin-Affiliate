use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Sledge::Plugin::Affiliate',
    'VERSION_FROM' => 'lib/Sledge/Plugin/Affiliate.pm', # finds $VERSION
    'PREREQ_PM'    => {
        URI::Escape             => 1.35,
        Test::More              => 0.32,
        LWP::UserAgent          => 2.033,
        Test::Exception         => 0.21,
        Class::Accessor::Fast   => 0.22,
    },
);
