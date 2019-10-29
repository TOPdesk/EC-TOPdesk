package FlowPlugin::TOPdesk;
use strict;
use warnings;
use base qw/FlowPDF/;
use Data::Dumper;
use DateTime;
use List::Util "min";
# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName    => '@PLUGIN_KEY@',
        pluginVersion => '@PLUGIN_VERSION@',
        configFields  => ['config'],
        configLocations => ['ec_plugin_cfgs']
    };
}

# Auto-generated method for the procedure createOperatorChange/createOperatorChange
# Add your code into this method and it will be called when step runs
use JSON;
sub createIncident {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    my $params = $context->getStepParameters();
    #print "Parameters: " . Dumper $params;
    # Config is an FlowPDF::Config object;
    my $config = $context->getConfigValues();
    #print "Configuration: " . Dumper $config;

    my $url = $config->getParameter('endpoint')->getValue();
    $url .= "/tas/api/incidents";

    my $requestField = '<b>Microservice:</b> '.$params->getParameter('microservice')->getValue().
                        '<br><b>Environment:</b> '.$params->getParameter('environment')->getValue().
                        '<br><b>Date/Time:</b> '.DateTime->now.
                        '<br><b>Process:</b> '.$params->getParameter('process')->getValue().
                        '<br><b>CloudBees Flow Url:</b> '.$params->getParameter('url')->getValue();
    my $externalNumber = $params->getParameter('externalNumber')->getValue();
    my $truncatedExternalNumber = substr($externalNumber, 0, min(60, length($externalNumber)));
    my $briefDescription = 'Cloudbees Flow failure: '.$externalNumber;
    my $truncatedBriefDescription = substr($briefDescription, 0, min(80, length($briefDescription)));
    #print  "briefDescription " . Dumper($truncatedBriefDescription);
    my $payload = {
             briefDescription => $truncatedBriefDescription,
             externalNumber => $truncatedExternalNumber,
             request => $requestField,
             callerLookup => {
                          id => $config->getParameter('callerId')->getValue()
             },
             processingStatus => {
                          id => $config->getParameter('processingStatusId')->getValue()
             },
             subcategory => {
                          id => $config->getParameter('subcategoryId')->getValue()
             },
             operatorGroup => {
                          id => $params->getParameter('operatorGroupId')->getValue()
             }
        };


    # loading component here using PluginObject;
    my $restComponent = $context->newRESTClient($config);
    my $request = $restComponent->newRequest('POST' => $url);
    $request->content(encode_json $payload);
    $request->header('Content-type', "application/json");

    if (my $cred = $config->getParameter('credential')) {
      my $user=$cred->getUserName();
      my $pwd =$cred->getSecretValue();
      $request->authorization_basic($user, $pwd);
    }
    #print  "Request: " . Dumper($request);

    my $response = $restComponent->doRequest($request);
    my $stepResult = $context->newStepResult();

    if ($response->is_success()) {
      #print "Success Response : " . Dumper $response;
      #print "Response decoded: " . Dumper $response->decoded_content;
      my $respContent = from_json($response->decoded_content);
      my $incidentId = $respContent->{id};
      $stepResult->setJobStepSummary("Incident $incidentId created successfully");
      $stepResult->setOutputParameter('incident', $response->decoded_content);
      $stepResult->setOutputParameter('incidentId', $incidentId);
    }
    else {
      $stepResult->setJobStepOutcome('error');
      $stepResult->setJobStepSummary("Failed POST request to $url");
      printf("Failed POST request to $url\n\t%s\n\n%s\n",$response->status_line,$response->decoded_content);
      # this will abort whole procedure during apply, otherwise just step will be aborted.
      # $stepResult->abortProcedureOnApply(1);
    }
    # $stepResult->apply();
    # print "Created stepresult\n";
    # $stepResult->setJobStepOutcome('warning');
    # print "Set stepResult\n";
    #
    # $stepResult->setJobSummary("See, this is a whole job summary");
    # $stepResult->setJobStepSummary('And this is a job step summary');

    $stepResult->apply();
}

sub createOperatorChange {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    my $params = $context->getStepParameters();
    #print "Parameters: " . Dumper $params;
    # Config is an FlowPDF::Config object;
    my $config = $context->getConfigValues();
    #print "Configuration: " . Dumper $config;

    my $url = $config->getParameter('endpoint')->getValue();
    $url .= "/tas/api/operatorChanges";

    my $pipelineRun = $params->getParameter('pipelineJob')->getValue();
    my $now = DateTime->now;
    my $flowUrl = $params->getParameter('url')->getValue();
    my $requestField = <<"END_MESSAGE";
A Pipeline run requires approval:

Pipeline Run: $pipelineRun
Date/Time: $now
CloudBees Flow Url: $flowUrl
END_MESSAGE
    my $externalNumber = $params->getParameter('externalNumber')->getValue();
    my $truncatedExternalNumber = substr($externalNumber, 0, min(60, length($externalNumber)));
    my $payload = {
             externalNumber => $truncatedExternalNumber,
             request => $requestField,
             requester => {
                          id => $config->getParameter('callerId')->getValue()
             },
             template => {
                          number => $params->getParameter('templateNumber')->getValue()
             }
        };

    # loading component here using PluginObject;
    my $restComponent = $context->newRESTClient($config);
    my $request = $restComponent->newRequest('POST' => $url);
    $request->content(encode_json $payload);
    $request->header('Content-type', "application/json");

    if (my $cred = $config->getParameter('credential')) {
      my $user=$cred->getUserName();
      my $pwd =$cred->getSecretValue();
      $request->authorization_basic($user, $pwd);
    }
    #print  "Request: " . Dumper($request);

    my $response = $restComponent->doRequest($request);
    my $stepResult = $context->newStepResult();

    if ($response->is_success()) {
      #print "Success Response : " . Dumper $response;
      #print "Response decoded: " . Dumper $response->decoded_content;
      my $respContent = from_json($response->decoded_content);
      my $changeId=$respContent->{id};
      $stepResult->setJobStepSummary("Change request $changeId created successfully");
      $stepResult->setOutputParameter('change', $response->decoded_content);
      $stepResult->setOutputParameter('changeId', $changeId);
    }
    else {
      $stepResult->setJobStepOutcome('error');
      $stepResult->setJobStepSummary("Failed POST request to $url");
      printf("Failed POST request to $url\n\t%s\n",$response->status_line);
      # this will abort whole procedure during apply, otherwise just step will be aborted.
      # $stepResult->abortProcedureOnApply(1);
    }
    # $stepResult->apply();
    # print "Created stepresult\n";
    # $stepResult->setJobStepOutcome('warning');
    # print "Set stepResult\n";
    #
    # $stepResult->setJobSummary("See, this is a whole job summary");
    # $stepResult->setJobStepSummary('And this is a job step summary');

    $stepResult->apply();
}

sub getOperatorChange {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    my $params = $context->getStepParameters();
    my $config = $context->getConfigValues();

    my $url = $config->getParameter('endpoint')->getValue();
    my $id = $params->getParameter('changeId')->getValue();
    $url .= "/tas/api/operatorChanges/$id";

    # loading component here using PluginObject;
    my $restComponent = $context->newRESTClient();
    my $request = $restComponent->newRequest('GET' => $url);

    if (my $cred = $config->getParameter('credential')) {
      my $user=$cred->getUserName();
      my $pwd =$cred->getSecretValue();
      $request->authorization_basic($user, $pwd);
    }

    my $response = $restComponent->doRequest($request);
    my $stepResult = $context->newStepResult();

    if ($response->is_success()) {
      my $respContent = from_json($response->decoded_content);
      $stepResult->setJobStepSummary("Change request $id retrieved successfully");
      $stepResult->setOutputParameter('change', $response->decoded_content);
    }
    else {
      $stepResult->setJobStepOutcome('error');
      $stepResult->setJobStepSummary("Failed GET request to $url");
      printf("Failed GET request to $url\n\t%s\n",$response->status_line);
    }

    $stepResult->apply();
}
## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.

sub approveOrRejectPipelineGate {
    my ($pluginObject) = @_;
    my $context = $pluginObject->newContext();
    my $params = $context->getStepParameters();
    my $action = $params->getParameter('action')->getValue();
    printf($action == 1 ? "approved" : "rejected");
}

1;
