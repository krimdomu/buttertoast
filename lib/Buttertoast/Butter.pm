#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter;

use Moose;
use JSON::XS;
use Data::Dumper;
use Proc::Fork;
use DateTime;
use Module::Load;

use Buttertoast::RedisProxy;

use Buttertoast::Butter::Config;

use Buttertoast::Butter::Command::List;
use Buttertoast::Butter::Command::Create;
use Buttertoast::Butter::Command::Start;

use Buttertoast::Butter::Metric::Memory;

use Buttertoast::Butter::Placement::Simple;

use Buttertoast::Butter::Network::Inbound::HAProxy;

use Buttertoast::Butter::DNS;

has driver => (
    is => 'rw',
    default => sub {"Docker"},
);

has redis_rw => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

has redis_sub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

has redis_pub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

has metrics => (
    is => 'rw',
    default => sub { [qw/Memory/] }
);

has client_uuid => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config->id;
    },
);

has placement => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $placement_class = "Buttertoast::Butter::Placement::" . $self->config->placement;
        return $placement_class->new(butter => $self);
    },
);

has dns => (
    is => 'rw',
    lazy => 1,
    default => sub { my $self = shift; Buttertoast::Butter::DNS->new(butter => $self); }
);

has inbound_ip => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config->inbound_ip;
    },
);

has inbound_traffic_mgr => (
    is => 'ro',
    isa => 'Buttertoast::Butter::Network::Inbound',
    lazy => 1,
    default => sub { my $self = shift; Buttertoast::Butter::Network::Inbound::HAProxy->new(butter => $self); }
);

has priority_level => (
    is => 'ro',
    default => sub { rand(1_000_000) },
);

has config => (
    is => 'ro',
    default => sub { Buttertoast::Butter::Config->new; }
);

sub get_file {
    my $self = shift;
    my $file = shift;

    return eval { local(@ARGV, $/) = ("files/butter/$file"); <>; };
}

sub who_is_master {
    my $self = shift;

    my @cluster_member_keys = $self->redis_rw->keys("cluster:priority:*");
    my $master = {
        prio => $self->priority_level,
        node => $self->client_uuid,
    };
    for my $cl_m (@cluster_member_keys) {
        my $o_cl_m = $cl_m;
        my ($uuid) = ($cl_m =~ m/^cluster:priority:(.*)$/);
        my $value = $self->redis_rw->get($o_cl_m);
        if($value > $master->{prio}) {
            $master->{prio} = $value;
            $master->{node} = $uuid;
        }
    }

    return $master->{node};
}

sub dispatch_cluster_command {
    my ($self, $command) = @_;
    print "[+] got message on cluster communication channel...\n";

    if($command->{on_node} eq $self->client_uuid) {
        print "[|] command is for me...\n";
        eval {

            my $class_to_call = "Buttertoast::Butter::Command::" . $command->{command};
            my $mod = $class_to_call->new(butter => $self);

            $mod->execute($command->{count}, @{$command->{arguments}});

            print "[+] done.\n";

            1;
        } or do {
            print "[!] $@\n";
            die $@;
        };
    }
}

sub dispatch_communication_command {
    my ($self, $command) = @_;
    
    my $master = $self->who_is_master;

    if($master eq $self->client_uuid) {
        print "[+] master is me :)\n";

        my $class_to_call = "Buttertoast::Butter::Command::" . $command->{command};
        my $mod = $class_to_call->new(butter => $self);

        my $ret = {};

        if($mod->need_placement) {
            print "[|] this command needs placement\n";
            my $placement = $self->client_uuid;
            my @placement = $mod->calculate_placement(@{$command->{arguments}});

            my @cluster_commands = $mod->generate_cluster_command(\@placement, @{$command->{arguments}});
            print "[|] sending command to: " . $_->{on_node} . "\n" for @cluster_commands;
            $self->redis_pub->publish("vessel_cluster_comm", encode_json($_)) for @cluster_commands;

            print "[+] commands send.\n";

            $ret = {
                rpc => "1.0",
                id => $command->{id},
                return => {
                    ok => 1,
                },
            };
        }
        else {
            print "[+] command doesn't need placement.\n";
            $ret = {
                rpc => "1.0",
                id => $command->{id},
                return => $mod->execute(@{$command->{arguments}}),
            };
        }


        $self->redis_pub->publish("vessel_command_comm__ret_" . $ret->{id}, encode_json($ret));
    }
}

sub send_event {
    my $self = shift;
    my $event = shift;

    $self->redis_pub->publish("vessel_events", $event->to_string);
    $self->inbound_traffic_mgr->refresh;
}

sub collect_metrics {
    my $self = shift;
    while(1) {
        print "[-] Collection metrics ...\n";
        for my $m ($self->metrics->@*) {
            my $metric_class = "Buttertoast::Butter::Metric::$m";
            my $metric = $metric_class->new;
            my $value = $metric->execute;
            my $key = "metric:" . $self->client_uuid . ":\L$m";
            $self->redis_rw->set($key => $value);
        }
        sleep 15;
    }
}

sub heartbeat {
    my $self = shift;
    my $key = "alive:" . $self->client_uuid;
    while(1) {
        print "[-] sending heartbeat ...\n";
        $self->redis_rw->set($key => DateTime->now->epoch);
        sleep 5;
    }
}

sub register {
    my $self = shift;
    $self->redis_rw->setnx("cluster:priority:" . $self->client_uuid, $self->priority_level);
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
    my @metric_keys = $self->redis_rw->keys("metric:" . $self->client_uuid . ":*");

    $self->redis_rw->del($_) for @metric_keys;
    $self->redis_rw->del("cluster:priority:" . $self->client_uuid);
    $self->redis_rw->del("alive:" . $self->client_uuid);

    print "[+] done ...\n";

    CORE::exit();
}

sub start_driver {
    my $self = shift;

    my $driver_class = "Buttertoast::Butter::Driver::" . $self->driver;
    load $driver_class;

    my $driver = $driver_class->new(butter => $self);
    $driver->listen_for_events;
}

sub start {
    my $self = shift;

    run_fork {
        child {
            $self->dns->start;
        }
    };

    run_fork {
        child {
            $self->start_driver;
        }
    };

    run_fork {
        child {
            $self->collect_metrics;
        }
    };

    run_fork {
        child {
            $self->heartbeat;
        }
    };

    $self->register;
    $self->handle_signals;

    $self->redis_sub->subscribe(
        'vessel_command_comm',
        'vessel_cluster_comm',
        sub {
            my ($message, $topic, $subscribed_topic) = @_;
            # print "message: $message\n";
            # print "topic: $topic\n";
            # print "subscribed_topic: $subscribed_topic\n";
            if($topic eq "vessel_command_comm") {
                my $json = decode_json $message;
                $self->dispatch_communication_command($json);
            }
            if($topic eq "vessel_cluster_comm") {
                my $json = decode_json $message;
                $self->dispatch_cluster_command($json);
            }
        }
    );

    print "[~] Buttertoast getting toasted...\n";
    my $timeout = 10;
    $self->redis_sub->wait_for_messages($timeout) while 1;
}


1;
