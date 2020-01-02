package Buttertoast::Marmelade::Config::Redis;

use Moose;

has host => (
    is => 'rw',
    default => sub { "localhost" },
);

has port => (
    is => 'rw',
    default => sub { 6379 },
);

1;
