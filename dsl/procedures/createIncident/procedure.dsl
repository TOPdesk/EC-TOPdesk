// This procedure.dsl was generated automatically
// === procedure_autogen starts ===
procedure 'createIncident', description: 'Create a new incident', {

    step 'createIncident', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/createIncident/steps/createIncident.pl").text
        shell = 'ec-perl'

        }

    formalOutputParameter 'incident',
        description: 'JSON representation of the created incident'

    formalOutputParameter 'incidentId',
        description: 'Incident ID of the created incident'
// === procedure_autogen ends, checksum: d8b6bc3869b66fb42b11781d564d29e8 ===
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}
