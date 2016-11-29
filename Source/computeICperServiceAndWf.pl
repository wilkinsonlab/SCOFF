# Call: perl computeICperServiceAndWf.pl <path ontology Annotations files> <path ICvalue per individual annotation> <Output-IntermediateFile> <Output-Wf and Service IC withIN redundant>

# Example: perl computeICperServiceAndWf.pl "../Data/WF_myExperiment/NotRedundantAnnot/" "SML_toolkit/ICvalues/results/XXX_results_ICI.csv" wf_service_annotation_IC.txt wfAndServiceI.txt


use strict;
use warnings;


# Subroutines
################################################################
# load_hash_IC_annotation
################################################################
sub load_hash_IC_annotation($$\%) {
  # Use: %hash=load_hash_IC_annotation($ont,$fileOnt,%hash_ont_MainProgram);
  # Parameters
  my $ont = shift;
  my $file = shift;  
  my %hash = %{(shift)};

  my ($url, $label, $idEDAM);
  my @line;

  open(F,"<$file");
  while(<F>){
      @line=split("\\t",$_);
      if(!($line[2] =~ "Resnik")){ # To ignore heading	  
	  # iciZhou: column 4. If iciSeco: column 3, elsif iciSanchez: column 5.
	  $hash{$line[0]}=$line[3];
      } # end-if
  } #end-while file
  close(F);
  return(%hash);
}

################################################################
# print_hash
################################################################
sub print_hash(\%) {
  # Parameters
  my %hash = %{(shift)};

  foreach my $term (sort keys %hash){
      print("$term\t$hash{$term}\n");
  } #end-foreach
}



###########################################################################
#
############################## MAIN PROGRAM ###############################
#
###########################################################################

my $dirAnnot=$ARGV[0];
my $pathICfile=$ARGV[1];
my $fileInter=$ARGV[2];
my $fileOut=$ARGV[3];


# To load IC values per ontology class in a hash of hash (split by ontology)
my ($fileOnt, $ont, @arrOnt, %hashes);
@arrOnt = ();
push(@arrOnt,"EDAM");
push(@arrOnt,"BAO");
push(@arrOnt,"OBIWS");
push(@arrOnt,"BRO");
push(@arrOnt,"IAO");
push(@arrOnt,"MS");
push(@arrOnt,"MESH"); # Take care MESHdesc
push(@arrOnt,"OBI");
push(@arrOnt,"SWO");
push(@arrOnt,"EFO");
push(@arrOnt,"NCIT");
push(@arrOnt,"NIFSTD");
push(@arrOnt,"SIO");

foreach $ont (@arrOnt){
    ($fileOnt = $pathICfile) =~ s/XXX/$ont/; 
    %{$hashes{$ont}}=load_hash_IC_annotation($ont,$fileOnt,%{$hashes{$ont}});
    
   #print("---------------------\nOntology $ont:\n");
   #print_hash(%{$hashes{$ont}});
} #end-foreach

# To write intermediate file: To get a tabular file: wf_ID, service name, 4 fields of annotation (Ontology, annnot_id, label, URI), IC
# Building input directory
my ($l, $lastChar);
$l=length($dirAnnot);
$lastChar=substr($dirAnnot,$l-1,$l);
if($lastChar ne '/'){
    $dirAnnot=$dirAnnot."/";
} #end-if

my $template="wf_myExperiment_*_edamAnnotations.txt";
my @files=<$dirAnnot$template>; #my @files=<../Data/WF_myExperiment/wf_myExperiment_*_edamAnnotatins.txt>;
my ($wfId, @line, @line1, @line2, $servID, $uri, $ic, $maxIC, $totIC, $avgIC, $contServ);

open(FOUT,">$fileInter");
print(FOUT "#Workflow\tService\tOntology\tId\tLabel\tURI\tICI_Zhou_etal\n");
open(Fwith,">$fileOut");
print(Fwith "#Workflow\tService\tIC_serv\tWorkflow\tIC_wf\n");
foreach my $wfFile (@files){
    # New workflow
    @line1=split("wf_myExperiment_",$wfFile);
    @line2=split("\_edamAnnotations.txt",$line1[1]);
    $wfId=$line2[0];

    $totIC=0;
    $avgIC=0;    
    $contServ=0;
    $maxIC=0;
    open(F,"<$wfFile");
    while(<F>){
	chomp;
	if($_ =~ "^service name:"){
	    # Counts related to old service
	    if($contServ > 0){
		print(Fwith "$wfId\t$servID\t$maxIC\n");
	    }
	    $totIC=$totIC+$maxIC;	 
	    $contServ=$contServ+1;
	    # To change to a new service, every time a new service appears.
	    @line=split("\: ",$_);
	    $servID=$line[1];
	    # Counts related to new service
	    $maxIC=0;
	}elsif(($_ =~ "^\tEDAM")||($_ =~ "^\tBAO")||($_ =~ "^\tOBIWS")||($_ =~ "^\tBRO")||($_ =~ "^\tIAO")||($_ =~ "^\tMS")||($_ =~ "^\tMESH")||($_ =~ "^\tOBI")||($_ =~ "^\tSWO")||($_ =~ "^\tEFO")||($_ =~ "^\tNCIT")||($_ =~ "^\tNIFSTD")||($_ =~ "^\tSIO")){
	    # New annotation
	    @line=split("\\t",$_);
	    $ont=$line[1];
	    $uri=$line[4];
 	    if(exists $hashes{$ont}{$uri}){
 		$ic=$hashes{$ont}{$uri};
		if($ic != -1){
		    print(FOUT "$wfId\t$servID\t$ont\t$line[2]\t$line[3]\t$uri\t$ic\n");
		    if($ic > $maxIC){
			$maxIC=$ic;
		    }
		} #end-if IC!=-1
	    } #end-if exists IC
	} # end-if
    } #end-while file
    close(F);
    if($contServ == 1){
	$avgIC=$maxIC;
	# Print the info of that service
	print(Fwith "$wfId\t$servID\t$maxIC\n");
	print(Fwith "\t\t\t$wfId\t$avgIC\n");
    }elsif($contServ == 0){
	# Nothing, not services with annotations in this workflow.
    }else{
	$avgIC=$totIC/$contServ;
        #print(Fwith "\t\t----------------------------\t----------------------------\t$wfId\t$avgIC\n");
	print(Fwith "\t\t\t$wfId\t$avgIC\n");
    }
    $totIC=0;
    $avgIC=0;    
    $contServ=0;
    $maxIC=0;
} # end-foreach workflow
close(FOUT);
close(Fwith);


