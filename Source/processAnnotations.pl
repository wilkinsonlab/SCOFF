# Call: perl processAnnotations.pl <dirOut>
# Example call: perl processAnnotations.pl $HOME/Data/WF_myExperiment

use strict;
use warnings;
use File::Copy;

################################################################
# delete_hash
################################################################
sub delete_hash(\%) {
  # Parameters
  my %hash = %{(shift)};

  foreach my $term (keys %hash){
      delete $hash{$term};
  } #end-foreach
  return(%hash);
}


################################################################
# sub remove_unknown_services_annotations
################################################################
sub remove_unknown_services_annotations($$){
  # Use: remove_unknown_services_annotations($fileIn,$fileOut);
  # Parameters
  my $fileIn = shift;  
  my $fileOut = shift;  
  
  my ($servName, $servType, $uriName, $copyService);

  $copyService=0;
  open(IN,"<$fileIn") or die "Couldn't open: $fileIn";
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  while(<IN>){
      if($_ =~ "^---------------"){
	  # New service
	  $servName="";
	  $servType="";
	  $uriName="";
	  $copyService=0;	  
      }elsif($_ =~ "^service name:"){
	  chomp;
	  $servName=$_;
      }elsif($_ =~ "^service type:"){
	  chomp;
	  $servType=$_;
      }elsif($_ =~ "^URI:"){
	  $uriName=$_;
      }elsif(($_ =~ "^Description:")||($_ =~ "^\#\#\# description:")){
	  chomp;
	  # Check uri and servType, to determine if copy this service in the output or not
	  # ==> All services without URI and with service type<>biomoby.BiomobyObjectActivity, biomoby.MobyParseDatatypeActivity, Rshell, rshell.RshellActivity must be removed from *_edamAnnotations.txt files!!!!!!!! It gets to remove annotations from unknown services.
	  if($uriName ne "URI: \n"){
	      $copyService=1;
	  }elsif(($servType eq "service type: biomoby.BiomobyObjectActivity") || ($servType eq "service type: biomoby.MobyParseDatatypeActivity") || ($servType eq "service type: Rshell") || ($servType eq "service type: rshell.RshellActivity")){
	      $copyService=1;
	  }

	  if($copyService == 1){
	      print(OUT "\n-----------------------------------------------------------------------------\n");
	      print(OUT "$servName\n");
	      print(OUT "$servType\n");
	      print(OUT "$uriName");
	      print(OUT "$_\n");
	  } # end-if to copy service 
      }elsif($_ =~ "^Ontology annotations:"){
	  chomp;
	  if($copyService == 1){
	      print(OUT "$_\n");
	  }
      }elsif($_ =~ "^\t"){
	  chomp;
	  if($copyService == 1){
	      print(OUT "$_\n");
	  }
      }	  
  } # end-while
  close(IN);
  close(OUT);
} # end sub remove_unknown_services_annotations


################################################################
# sub not_redundant_services_annotations
################################################################
sub not_redundant_services_annotations($$){
  # Use: not_redundant_services_annotations($fileIn,$fileOut);
  # Parameters
  my $fileIn = shift;  
  my $fileOut = shift;  
  
  my ($numAnnot, @line, $update, $uri, %exists, %ontologyUri, %idTermUri, %labelUri, $currentOnt);

  %exists=delete_hash(%exists);
  %ontologyUri=delete_hash(%ontologyUri);
  %idTermUri=delete_hash(%idTermUri);
  %labelUri=delete_hash(%labelUri);
  $currentOnt="";
  $update=0;
  $uri="";

  open(IN,"<$fileIn") or die "Couldn't open: $fileIn";
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  while(<IN>){
      if($_ eq "\n"){	  
	  # Not print
      }elsif($_ =~ "^---------------"){
	  # New service
	  # To write not redundant annotations
	  $numAnnot=(scalar keys %exists); # To get number of annotations.
	  if($numAnnot > 0){ 
	      foreach $uri (keys %exists){
		  print(OUT "\t$ontologyUri{$uri}\t$idTermUri{$uri}\t$labelUri{$uri}\t$uri\n");
	      } #end-foreach
	  } # If not first service
	  print(OUT "\n-----------------------------------------------------------------------------\n");
	  # To remove hashes and to initialize 
	  %exists=delete_hash(%exists);
	  %ontologyUri=delete_hash(%ontologyUri);
	  %idTermUri=delete_hash(%idTermUri);
	  %labelUri=delete_hash(%labelUri);
	  $currentOnt="";
	  $update=0;
	  $uri="";

      }elsif(($_ =~ "^\tBAO") || ($_ =~ "^\tOBIWS") || ($_ =~ "^\tBRO") || ($_ =~ "^\tEDAM") || ($_ =~ "^\tIAO") || ($_ =~ "^\tMS") || ($_ =~ "^\tMESH") || ($_ =~ "^\tOBI") || ($_ =~ "^\tSWO") || ($_ =~ "^\tNCIT") || ($_ =~ "^\tNIFSTD") || ($_ =~ "^\tSIO") || ($_ =~ "^\tEFO")){
	  chomp;
	  @line=split("\\t",$_);
	  $uri=$line[4];
	  $update=0;

	  if(!defined($exists{$uri})){
	      # To store new URI as annotation
	      $exists{$uri}++;
	      $ontologyUri{$uri}=$line[1];
	      $idTermUri{$uri}=$line[2];
	      $labelUri{$uri}=$line[3];
	  }else{
	      # To decide if the ontology associated to the URI should be updated or not, depending on import relation among ontologies.
	      $currentOnt=$line[1];
	      if(($currentOnt eq "SWO") && ($ontologyUri{$uri} eq "EDAM")){
		  $update=1;
	      }elsif(($currentOnt eq "SWO") && ($ontologyUri{$uri} eq "IAO")){
		  $update=1;
	      }elsif(($currentOnt eq "SWO") && ($ontologyUri{$uri} eq "OBI")){
		  $update=1;
	      }elsif(($currentOnt eq "SWO") && ($ontologyUri{$uri} eq "OBIWS")){
		  $update=1;
	      }elsif(($currentOnt eq "OBIWS") && ($ontologyUri{$uri} eq "IAO")){
		  $update=1;
	      }elsif(($currentOnt eq "OBIWS") && ($ontologyUri{$uri} eq "OBI")){
		  $update=1;
	      }elsif(($currentOnt eq "OBIWS") && ($ontologyUri{$uri} eq "BAO")){
		  $update=1;
	      }elsif(($currentOnt eq "OBI") && ($ontologyUri{$uri} eq "BAO")){
		  $update=1;
	      }elsif(($currentOnt eq "EFO") && ($ontologyUri{$uri} eq "BAO")){
		  $update=1;
	      }elsif(($currentOnt eq "EFO") && ($ontologyUri{$uri} eq "IAO")){
		  $update=1;
	      }elsif(($currentOnt eq "EFO") && ($ontologyUri{$uri} eq "OBI")){
		  $update=1;
	      }elsif(($currentOnt eq "EFO") && ($ontologyUri{$uri} eq "OBIWS")){
		  $update=1;
	      }elsif(($currentOnt eq "EFO") && ($ontologyUri{$uri} eq "SWO")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "BAO")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "BRO")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "EFO")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "IAO")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "OBI")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "OBIWS")){
		  $update=1;
	      }elsif(($currentOnt eq "NIFSTD") && ($ontologyUri{$uri} eq "SWO")){
		  $update=1;
	      }else{
		  print("Ontology not updated: currentOnt=$currentOnt vs oldOnt=$ontologyUri{$uri}: $uri\n");
	      } # end if current-old ontology

	      if($update == 1){
		  $ontologyUri{$uri}=$line[1];
		  $idTermUri{$uri}=$line[2];
		  $labelUri{$uri}=$line[3];		  
	      } # end-if update=1
	  } # end-else redundant annotations
      }else{
	  print(OUT "$_");
      } # if new line
  } # end-while
  # To print the annotations of the last service
  foreach $uri (keys %exists){
      print(OUT "\t$ontologyUri{$uri}\t$idTermUri{$uri}\t$labelUri{$uri}\t$uri\n");
  } #end-foreach
  close(IN);
  close(OUT);

} # end sub not_redundant_services_annotations

################################################################



# Building output directory
my $dirOut=$ARGV[0];
my $firstChar=substr($dirOut,0,1);
if($firstChar ne "/"){
    die ">>ERROR in argument: The directoty must be an ABSOLUTE path (not a relative one)";
}
my $l=length($dirOut);
my $lastChar=substr($dirOut,$l-1,$l);
if($lastChar ne '/'){
    $dirOut=$dirOut."/";
} #end-if

my $prefix="wf_myExperiment_*";
my @files=<$dirOut$prefix>; #my @files=<../Data/WF_myExperiment/wf_myExperiment_*>;
my ($wfId, $ext, @line1, @line2, $annotIn, $annotOut);

chdir($dirOut);
mkdir("NewAnnot");
my $dirRawAnnot=$dirOut."NewAnnot/";
mkdir("NotRedundantAnnot");
my $dirNotRedun=$dirOut."NotRedundantAnnot/";
foreach my $wfFile (@files){
    if((index($wfFile,"_edamAnnotations.txt")) > -1){
	@line1=split("wf_myExperiment_",$wfFile);
	@line2=split("\\_edamAnnotations.txt",$line1[1]);
	$wfId=$line2[0];

	print("\n*****WORKFLOW $wfId\n");       
#	$annotIn="wf_myExperiment_".$wfId."_edamAnnotations.txt";
#	move($annotIn,$dirRawAnnot);

	# First: to remove unknown services and their annotations.
	$annotIn=$dirOut."wf_myExperiment_".$wfId."_edamAnnotations.txt";
	$annotOut=$dirRawAnnot."wf_myExperiment_".$wfId."_edamAnnotations.txt";
	remove_unknown_services_annotations($annotIn,$annotOut);

	# Second: to remove redundant annotations.
	$annotIn=$annotOut;
	$annotOut=$dirNotRedun."wf_myExperiment_".$wfId."_edamAnnotations.txt";
	not_redundant_services_annotations($annotIn,$annotOut);

    } # end-if original file is an annotation file
} # end-foreach workflow

