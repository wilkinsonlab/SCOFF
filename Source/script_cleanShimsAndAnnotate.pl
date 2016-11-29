# Call: perl script_cleanShimsAndAnnotate.pl <dirOut>
# Example call: perl script_cleanShimsAndAnnotate.pl ../Data/WF_myExperiment >& output_cleanShimsAndAnnotate_

# Building output directory
my $dirOut=@ARGV[0];
my $l=length($dirOut);
my $lastChar=substr($dirOut,$l-1,$l);
if($lastChar ne '/'){
    $dirOut=$dirOut."/";
} #end-if

my $prefix="wf_myExperiment_*";
my @files=<$dirOut$prefix>; #my @files=<../Data/WF_myExperiment/wf_myExperiment_*>;
my ($wf_id, $ext, @line1, @line2, $wfShims, $wfAnnot);

foreach my $wfFile (@files){
    if(((index($wfFile,"_withoutShims")) == -1) && ((index($wfFile,"_edamAnnotations.txt")) == -1)){
	@line1=split("\wf_myExperiment_",$wfFile);
	@line2=split("\\.",@line1[1]);
	$wfId=$line2[0];
	$ext=$line2[1];

	print("\n*****WORKFLOW $wfId.$ext\n");
	$wfShims=$dirOut."wf_myExperiment_".$wfId."_withoutShims.".$ext;
	$wfAnnot=$dirOut."wf_myExperiment_".$wfId."_edamAnnotations.txt";
	system("perl clean_shims.pl $wfFile $wfShims");
	system("perl getDescriptionAndAnnotateWf.pl $wfShims $wfAnnot");
    } # end-if original file (not output file, i.e. _withoutShims or _edamaAnnotations file)
} # end-foreach workflow

