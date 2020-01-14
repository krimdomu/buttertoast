package Buttertoast::Toast::Config::Redis;

use Moose;

has host => (
    is => 'rw',
    default => sub { "localhost" },
);

has port => (
    is => 'rw',
    default => sub { 6379 },
);

has encryption_key => (
    is => 'rw',
);

has prefix => (
    is => 'rw',
    lazy => 1,
    default => sub { "" }
);

1;
