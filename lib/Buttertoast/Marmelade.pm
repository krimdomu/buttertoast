#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade;

use Moose;
use Redis;
use Proc::Fork;
use JSON::XS;
use UUID::Tiny ':std';

use Data::Dumper;

use Buttertoast::Marmelade::Config;
use Buttertoast::Marmelade::Command::Start;
use Buttertoast::Marmelade::Command::Die;
use Buttertoast::Marmelade::Driver::Nginx;

has redis_rw => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Redis->new(server => $self->config->redis->host  . ":" . $self->config->redis->port);
    }
);

has redis_sub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Redis->new(server => $self->config->redis->host  . ":" . $self->config->redis->port);
    }
);

has redis_pub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Redis->new(server => $self->config->redis->host  . ":" . $self->config->redis->port);
    }
);

has config => (
    is => 'rw',
    default => sub { Buttertoast::Marmelade::Config->new }
);

has marmelade_id => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config->id;
    },
);

has ingress => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift; 
        my $driver_class = "Buttertoast::Marmelade::Driver::" . $self->config->driver;
        return $driver_class->new(marmelade => $self);
    },
);

sub get_file {
    my $self = shift;
    my $file = shift;

    return eval { local(@ARGV, $/) = ("files/marmelade/$file"); <>; };
}

sub handle_signals {
    my $self = shift;

    $SIG{INT}  = sub { $self->shutdown; };
    $SIG{TERM}  = sub { $self->shutdown; };
}

sub shutdown {
    my $self = shift;

    print "\r[+] shuting down ...\n";
    print "[|] cleaning up ...\n";
    my @keys = $self->redis_rw->keys("marmelade:" . $self->marmelade_id . ":*");
    $self->redis_rw->del($_) for @keys;
    print "[+] done ...\n";

    CORE::exit();
}

sub dispatch_event_command {
    my $self = shift;
    my $event = shift;

    eval {
        my $command_class = "Buttertoast::Marmelade::Command::" . ucfirst(lc($event->{type}));
        my $command = $command_class->new(marmelade => $self);
        $command->execute($event->{payload});
        1;
    } or do {
        print "[!] no command available (for " . $event->{type} . ") ...\n";
    };
}

sub start {
    my $self = shift;

    $self->ingress->start;

    $self->handle_signals;

    $self->redis_sub->subscribe(
        'vessel_events',
        sub {
            my ($message, $topic, $subscribed_topic) = @_;
            if($topic eq "vessel_events") {
                my $json = decode_json $message;
                $self->dispatch_event_command($json);
            }
        }
    );

    print "[~] Marmelade wants more sugar ...\n";
    my $timeout = 10;
    $self->redis_sub->wait_for_messages($timeout) while 1;
}

1;
