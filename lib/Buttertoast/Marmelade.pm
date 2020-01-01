#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade;

use Moose;
use Redis;
use JSON::XS;
use UUID::Tiny ':std';

use Data::Dumper;

use Buttertoast::Marmelade::Config;
use Buttertoast::Marmelade::Command::Start;
use Buttertoast::Marmelade::Command::Die;

has redis_rw => (
    is => 'rw',
    default => sub { Redis->new; }
);

has redis_sub => (
    is => 'rw',
    default => sub { Redis->new; }
);

has redis_pub => (
    is => 'rw',
    default => sub { Redis->new; }
);

has config => (
    is => 'rw',
    default => sub { Buttertoast::Marmelade::Config->new }
);

has marmelade_id => (
    is => 'rw',
    default => sub { "4905801a-1bc1-441c-a6c9-23dead4d8c8c" },
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

# $VAR1 = {                                    
#           'payload' => {                     
#                          'public' => '1',    
#                          'application_port' => '80',                                      
#                          'inbound_ip' => '172.20.10.4',                                   
#                          'container_id' => 'd8e23fdfcaf9ccadb4ca205452a5ddf9815d2238096728fec5d1d495ab168489',                                                                       
#                          'public_port' => '8888',                                         
#                          'container_ip' => '172.17.0.4'                                   
#                        },
#           'type' => 'START'
#         };

    print Dumper $event;

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
