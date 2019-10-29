// This procedure.dsl was generated automatically
// === procedure_autogen starts ===
procedure 'approveOrRejectPipelineGate', description: 'Approve or Reject the Pipeline', {

    step 'approveOrRejectPipelineGate', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/approveOrRejectPipelineGate/steps/approveOrRejectPipelineGate.pl").text
        shell = 'ec-perl'

        }
// === procedure_autogen ends, checksum: 171d7a7e8f6e40cdb6db5049c246d951 ===
// Do not update the code above the line
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}