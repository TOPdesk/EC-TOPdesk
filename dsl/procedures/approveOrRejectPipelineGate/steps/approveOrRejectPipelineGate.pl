#printf($[action] == 1 ? "approved" : "rejected");
use ElectricCommander;
use JSON;

my $ec = new ElectricCommander();

$|=1;

main();

sub bail_out {
    my ($message) = @_;
    $ec->setProperty(summary => $message);
    $ec->setProperty('/myJobStep/outcome', 'error');
    exit 1;
}
sub main {
    my $action;
    if ($[action] == 1) {
        $action = 'completed';
    }
    elsif ($[action] == 0) {
        $action = 'failed';
    }
    else {
        bail_out("Wrong value of action parameter($[action]) should be 1 or 0.");
    }

    my $prophash = parse_correlation_id("$[correlationId]");

    if (!$prophash) {
        bail_out("Wrong correlation ID");
    }
    my $proptext = gen_property($prophash);

    my $res;
    my $tries = 3;
    my $last_error = '';

    for (1 .. $tries) {
        eval {
            $res = $ec->completeManualTask({
                flowRuntimeId => $prophash->{flowRuntimeId},
                stageName => $prophash->{stageName},
                taskName => $prophash->{taskName},
                gateType => $prophash->{gateType},
                action => $action,
            });
        };
        last if $res;
        if ($@) {
            $last_error = $@;
        }
        sleep 10;
    }

    if ($last_error) {
        print "Error occured: $last_error\n";
        bail_out($last_error);
    }
    if ($res) {
        print "Will set property: $proptext\n";
        set_pipeline_properties($prophash->{flowRuntimeId}, $proptext, $[action]);
        print "Item with correlationId: $[correlationId] was successfully " . $action . "\n";
    }
}

# Will parse something like
sub parse_correlation_id {
    my ($correlationId) = @_;

    print "Correlation id : '$correlationId'\n";
    my @parsed = $correlationId =~ m|^/flowRuntime/(.*?)/stage/(.*?)/gate/(.*?)/taskName/(.*?)$|gsi;

    if (!$parsed[0] || !$parsed[1] || !$parsed[2] || !$parsed[3]) {
        print "parsing error.\n";
        return undef;
    }
    my $retval = {
        flowRuntimeId => $parsed[0],
        stageName => $parsed[1],
        gateType => $parsed[2],
        taskName => $parsed[3]
    };
    return $retval;
}

sub gen_property {
    my ($prophash) = @_;

    my $text = 'TOPdesk_Approval_' . $prophash->{stageName} . '_' . $prophash->{taskName};
    return $text;
}

sub set_pipeline_properties {
    my ($flowRuntimeId, $prop, $action) = @_;

    eval {
        my $res = $ec->getPipelineRuntimes({
            flowRuntimeId => $flowRuntimeId
        });
        my $flowRuntimeName = $res->findvalue('//flowRuntimeName')->string_value();
        my $projectName = $res->findvalue('//projectName')->string_value();

        if (!$flowRuntimeName || !$projectName) {
            print "Missing params\n";
            return;
        }
        print "Setting up the properties\n";
        my $prop_path = "/projects/$projectName/flowRuntimes/$flowRuntimeName";
        print "Prop path: $prop_path\n";
        my $r1 = $ec->setProperty($prop_path . "/TOPdeskApprovalInfo", $prop);
        my $r2 = $ec->setProperty($prop_path . "/TOPdeskApprovalAction", $action);
    };
    if ($@) {
        print "Error occured: $@\n";
    }
}
