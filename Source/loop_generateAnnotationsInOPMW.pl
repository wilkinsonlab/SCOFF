# Call: perl loop_generateAnnotationsInOPMW.pl <dirInWithoutShimsWf> <dirInOutAnnotations> [<dirInRedundantAnnotations>] [<pathTemplate_pairsURIannot-ICvalueFiles>] [[<TestWfID>]]
# IMP: Fourth parameter it is possible just if third one also exists!!! Fifth parameter depends on uncommenting a pair of lines of code.
# IMP: Fourth parameter must have included the string "XXXontXXX" in the template place where the ontology Id goes.

# 3rd parameter: <RedundantAnnotationsPath=../Data/WF_myExperiment/NewAnnot>: if this 3er parameter appears, the OPMW files split by ontologies must be computed, for all the ontologies. The path must contains the *_edamAnnotations.txt files per wf, before remove the redundant ones. It would be an additional step, preserving the hash with the links, but removing the previous annotations array and inserting the annotations corresponding to the specific ontology in each loop iteration.

# 4th parameter: <pathTemplate_pairsURIannot-ICvalueFiles=/home/beatriz/CBGP-PostDoc/ProjectWorkflows/Results/wf_annotation_IC_SemSimSubWfs_NewAnnot_XXX.txt>: only could appear if parameter 3 is. If this parameter 4 appears,  the OPMW files split by ontologies  WITH JUST 1 ANNOTATION (THE HIGHEST ic VALUE) must be computed.

# perl loop_generateAnnotationsInOPMW.pl ../Data/WF_myExperiment ../Data/WF_myExperiment/NotRedundantAnnot ../Data/WF_myExperiment/NewAnnot "../Results/wf_annotation_IC_SemSimSubWfs_NewAnnot_XXXontXXX.txt" 16 > ../Results/count_nodesAndLinks_perWf.txt


use strict;
use Data::Dumper;
use warnings;
use XML::LibXML;
use Cwd;
use URI::Escape;


############# TO-DO: To include $DIRsml as parameter or similar.
my $DIRsml="SML_toolkit";

################################################################
# generate_serv_annot_tab_file
################################################################
sub generate_serv_annot_tab_file($\@) {
# To generate tab file with wfId, nameServ, type, url-service, url-annotation
# Call: generate_serv_annot_tab_file(@files);

  # Parameters
  my $fileOut = shift;
  my @files = @{(shift)};
  
  my ($wfId, @line1, @line2);
  my (@line, $fileIn, $nameServ, $typeServ, $uriServ, $contAnnot, $contData, $uriAnnot, $contBiomart, $contRshell, $contServices, $opaqueUri, $okToPrint);

  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "#WfId\tServiceName\tServiceType\tURI\tOpaqueURI\tAnnotationURI\n");
  foreach my $wfFile (@files){
      if((index($wfFile,"_edamAnnotations.txt")) > -1){
	  @line1=split("wf_myExperiment_",$wfFile);
	  @line2=split("\\_edamAnnotations.txt",$line1[1]);
	  $wfId=$line2[0];

	  open(IN,"<$wfFile") or die "Couldn't open: $wfFile";

	  $uriServ="";
	  $nameServ="";
	  $typeServ="";
	  $opaqueUri="";
	  $contData=0;
	  $contAnnot=0;
	  $contBiomart=1;
	  $contRshell=1;
	  $contServices=1;
	  $okToPrint=1; # If service isn't a Biomoby Object.
	  while(<IN>){
	      if($_ =~ "^---------------"){
		  if($okToPrint){
		      if($contData > 0){
			  # Print remainder lines last service
			  if($contAnnot == 0){
			      # Write line with the uri of the Serv, when it has not annotations. 
			      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t$opaqueUri\t---\n");
			  } # end-if $contAnnot<=0
		      } # end-if $contData > 0
		  } # end-if okToPrint
		  # To initialize new service
		  $uriServ="";
		  $nameServ="";
		  $typeServ="";
		  $opaqueUri="";
		  $contAnnot=0;
		  $contData=$contData+1;
		  $okToPrint=1;
		 
	      }elsif($_ =~ "^service name:"){
		  chomp;
		  ($nameServ = $_) =~ s/^service name:[[:space:]]*//;
		  
	      }elsif($_ =~ "^service type:"){
		  chomp;
		  ($typeServ = $_) =~ s/^service type:[[:space:]]*//;
		  if(($typeServ eq "biomart.BiomartActivity") || ($typeServ eq "BioMart")){
		      $uriServ="http://www.biomart.org/biomart/martservice/$wfId:$contBiomart";
		      $contBiomart=$contBiomart+1;
		  }elsif(($typeServ eq "rshell.RshellActivity") || ($typeServ eq "Rshell")){
		      $uriServ="http://rshellservice/$wfId:$contRshell";
		      $contRshell=$contRshell+1;
		  }elsif(($typeServ eq "biomoby.BiomobyObjectActivity") || ($typeServ eq "biomoby.MobyParseDatatypeActivity")){
		      $okToPrint=0;
		  }# end-if Biomart or Rshell or BiomobyObject

	      }elsif($_ =~ "^URI:"){
		  chomp;
		  if($uriServ eq ""){ 
		      ($uriServ = $_) =~ s/^URI:[[:space:]]*//;
		      $uriServ =~ s/ \[/#/;
		      $uriServ =~ s/\]//;
		  } # end-if uri hadn't already fixed (Biomart or Rshell)
		  if($typeServ eq "BioMoby"){
		      if(grep(!/^http/,$uriServ) == 1){
			  $uriServ="http://moby.ucalgary.ca/moby/MOBY-Central.pl";
		      } # end-if
		  } # end-if
		  $opaqueUri="http://www.wilkinsonlab.info/myExperiment_Annotations/workflowTemplateProcess/wf".$wfId."/serv".$contServices;
		  $contServices=$contServices+1;
		  
	      }elsif(($_ =~ "^\tBAO") || ($_ =~ "^\tOBIWS") || ($_ =~ "^\tBRO") || ($_ =~ "^\tEDAM") || ($_ =~ "^\tIAO") || ($_ =~ "^\tMS") || ($_ =~ "^\tMESH") || ($_ =~ "^\tOBI") || ($_ =~ "^\tSWO") || ($_ =~ "^\tEFO") || ($_ =~ "^\tNCIT") || ($_ =~ "^\tNIFSTD") || ($_ =~ "^\tSIO")){
		  chomp;
		  @line=split("\\t",$_);
		  $uriAnnot=$line[4];
		  
		  if($okToPrint){
		      $contAnnot=$contAnnot+1;
		      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t$opaqueUri\t$uriAnnot\n");
		  } # end-if okToPrint
	      } # end-if type of line in annotation file
	  } # end-while
	  # Print remainder lines last service
	  if($okToPrint){
	      if($nameServ ne ""){ # It really exists some services. To avoid write lines for empty workflows.
		  if($contAnnot == 0){ # Write line with the uri of the Serv, when it has not annotations. 
		      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t$opaqueUri\t---\n");
		  } # end-if $contAnnot>0
	      } # end-if some annotated service exists
	  } # end-if okToPrint
	  close(IN);  
      } # end-if original file is an annotation file
  } # end-foreach workflow
  close(OUT);
} # end-sub generate_serv_annot_tab_file



################################################################
# delete_hash
################################################################
sub delete_hash(%) {
  # Parameters
  my %hash = %{(shift)};

  foreach my $term (keys %hash){
      delete $hash{$term};
  } #end-foreach
  return(%hash);
} # end-sub delete_hash


################################################################
# load_annotation_uris
# From file: #WfId \t Service name \t URI \t Annotation URI
################################################################
sub load_annotation_uris($\@){
# Use: @listURIs=load_annotation_uris($fileAnnotURIs,@listURIs);
# IMPORTANT: In biomart and Rshell, hash id 'servUri' and $list[$wfId]{$servName}{$servUri}{'URI'} haven't the same value!!!!!!!!
  my $file = shift;
  my @list = @{(shift)};
  my (@line, $wfId, $servName, $servType, $servUri, $annotUri, $abstractUri, $opaqueUri);
  
  
  open(IN,"<$file") or die "Couldn't open: $file";
  while(<IN>){
      if(!($_ =~ "^#")){
	  chomp;
	  @line=split("\\t",$_);
	  
	  $wfId=$line[0];
	  $servName=$line[1];
	  $servType=$line[2];
	  $servUri=$line[3];
	  $opaqueUri=$line[4];
	  $annotUri=$line[5];
	  if(($servType eq "Rshell") || ($servType eq "rshell.RshellActivity")){
	      $abstractUri="http://rshellservice";
	  }elsif(($servType eq "BioMart") || ($servType eq "biomart.BiomartActivity")){
	      $abstractUri="http://www.biomart.org/biomart/martservice";
	  }else{
	      $abstractUri=$servUri;
	  }
	  $list[$wfId]{$servName}{$abstractUri}{'URI'}=$servUri; # I can't define a hash with wfId as ref!!
	  $list[$wfId]{$servName}{$abstractUri}{'type'}=$servType;
	  $list[$wfId]{$servName}{$abstractUri}{'opaqueURI'}=$opaqueUri;

	  if(defined $annotUri){
	      if($annotUri ne "---"){
		  push(@{$list[$wfId]{$servName}{$abstractUri}{'annot'}},$annotUri);
	      }
	  } # end-if exists annot
      } # skip header
  } # end-while
  close(IN);

  return(@list);
} # end-sub load_annotation_uris


################################################################
# change_annotation_uris
################################################################
sub change_annotation_uris {
# Call:	change_annotation_uris($wfId,$ont,$fileIn,\%{$listURIs[$wfId]})
# It is a mix between: generate_serv_annot_tab_file and load_annotation_uris()
# To parse the NewAnnot/*_edamAnnotations.txt files, just loading annotation of specific ontology in the existing hash structure.
# It change the content of the structure %hashWf, deleting the old annotations in the annotations array (@{$hashWf{$servName}{$abstractUri}{'annot'}}) and inserting the new ones, from the $fileIn text annotation file.

  # Parameters
  my $wfId = shift;
  my $ont = shift;
  my $fileAnnot = shift;
  my %hashWf = %{(shift)};

  my (@line1, @line2);
  my (@line, $fileIn, $nameServ, $typeServ, $uriServ, $contAnnot, $uriAnnot, $contBiomart, $contRshell, $contServices, $opaqueUri, $okToPrint, $abstractUri);

  open(IN,"<$fileAnnot") or die "Couldn't open: $fileAnnot";

  $contBiomart=1;
  $contRshell=1;
  $contServices=1;
  while(<IN>){
      if($_ =~ "^---------------"){
	  # To initialize new service
	  $uriServ="";
	  $nameServ="";
	  $opaqueUri="";
	  $typeServ="";
	  $contAnnot=0;
	  $okToPrint=1; # If service isn't a Biomoby Object.
	  
      }elsif($_ =~ "^service name:"){
	  chomp;
	  ($nameServ = $_) =~ s/^service name:[[:space:]]*//;
	  
      }elsif($_ =~ "^service type:"){
	  chomp;
	  ($typeServ = $_) =~ s/^service type:[[:space:]]*//;
	  if(($typeServ eq "biomart.BiomartActivity") || ($typeServ eq "BioMart")){
	      $uriServ="http://www.biomart.org/biomart/martservice/$wfId:$contBiomart";
	      $contBiomart=$contBiomart+1;
	  }elsif(($typeServ eq "rshell.RshellActivity") || ($typeServ eq "Rshell")){
	      $uriServ="http://rshellservice/$wfId:$contRshell";
	      $contRshell=$contRshell+1;
	  }elsif(($typeServ eq "biomoby.BiomobyObjectActivity") || ($typeServ eq "biomoby.MobyParseDatatypeActivity")){
	      $okToPrint=0;
	  }# end-if Biomart or Rshell or BiomobyObject
	  
      }elsif($_ =~ "^URI:"){
	  chomp;
	  if($uriServ eq ""){ 
	      ($uriServ = $_) =~ s/^URI:[[:space:]]*//;
	      $uriServ =~ s/ \[/#/;
	      $uriServ =~ s/\]//;
	  } # end-if uri hadn't already fixed (Biomart or Rshell)
	  if($typeServ eq "BioMoby"){
	      if(grep(!/^http/,$uriServ) == 1){
		  $uriServ="http://moby.ucalgary.ca/moby/MOBY-Central.pl";
	      } # end-if
	  } # end-if
	  $opaqueUri="http://www.wilkinsonlab.info/myExperiment_Annotations/workflowTemplateProcess/wf".$wfId."/serv".$contServices;
	  $contServices=$contServices+1;

	  if($okToPrint){
	      if($contAnnot == 0){
		  if(($typeServ eq "Rshell") || ($typeServ eq "rshell.RshellActivity")){
		      $abstractUri="http://rshellservice";
		  }elsif(($typeServ eq "BioMart") || ($typeServ eq "biomart.BiomartActivity")){
		      $abstractUri="http://www.biomart.org/biomart/martservice";
		  }else{
		      $abstractUri=$uriServ;
		  } # end-if especial $typeServ

		  # To delete old annotations of these service, non Redundant ones:
		  @{$hashWf{$nameServ}{$abstractUri}{'annot'}}=();
	      } # end-if contAnnot==0
	  } # end-if okToPrint
	  
      }elsif($_ =~ "^\t${ont}[[:space:]]"){
	  chomp;
	  @line=split("\\t",$_);
	  $uriAnnot=$line[4];
	  
	  if($okToPrint){
	      $contAnnot=$contAnnot+1;
	      push(@{$hashWf{$nameServ}{$abstractUri}{'annot'}},$uriAnnot);
	  } # end-if okToPrint
      } # end-if type of line in annotation file
  } # end-while
  # Print remainder lines last service
  if($okToPrint){
      if($nameServ ne ""){ # It really exists some services. To avoid write lines for empty workflows.
	  $contAnnot=$contAnnot+1;
	  # I think this service hasn't annotations, but I should check it, to uncommented next two lines!!!!!!
	  #push(@{$hashWf{$nameServ}{$abstractUri}{'annot'}},$uriAnnot);
	  # print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t$opaqueUri\t---\n");
      } # end-if some annotated service exists
  } # end-if okToPrint
  close(IN);  
} # end-sub change_annotation_uris


################################################################
# getjustOne_annotation_uri
################################################################
sub getjustOne_annotation_uri {
# Call: getjustOne_annotation_uri($wfId,$ont,\%ICvalues,\%{$listURIs[$wfId]});
# It iterates the annotations array, comparing an IC of a term with the next one, preserving in a variable the URI and the IC value of the highest one. To preserve in the array just the URI of the annotation with the highest IC value.
# It change the content of the structure %hashWf, deleting the old annotations in the annotations array (@{$hashWf{$servName}{$abstractUri}{'annot'}}) and inserting just the new one.
# IMP: If there is just one annotation, it is preserved, independently on it has available IC value or not.
# IMP: If there are several URI with the same IC value, the first appearing is the preserved one. No special criterion.
# IMP: If the IC value is not available (it couldn't be computed for some reason) that annotation is ignored.

  # Parameters
  my $wfId = shift;
  my $ont = shift;
  my %hashICvaluesOnt = %{(shift)};
  my %hashWf = %{(shift)};

  # Local variables
  my ($highestICvalue, $bestAnnotUri);

  foreach my $servName (keys %hashWf){
      $highestICvalue=-2;
      $bestAnnotUri="";      
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  if(scalar (@{$hashWf{$servName}{$servUri}{'annot'}}) > 1){
	      #print("\n$servName:\n");
	      # To look for the annotation with the highest IC value
	      for my $termUri (@{$hashWf{$servName}{$servUri}{'annot'}}){
		  if(defined $hashICvaluesOnt{$termUri}){
		      #print("$termUri: ".$hashICvaluesOnt{$termUri}."\n");
		      if($hashICvaluesOnt{$termUri} > $highestICvalue){
			  $highestICvalue=$hashICvaluesOnt{$termUri};
			  $bestAnnotUri=$termUri;		      
		      } # end-if better IC value
		  } # end-if defined ICvalue per this term
	      } # end-for annotation
	      # To delete all annotations, except to that one with the highest IC value
	      @{$hashWf{$servName}{$servUri}{'annot'}}=();
	      if($bestAnnotUri ne ""){
		  push(@{$hashWf{$servName}{$servUri}{'annot'}},$bestAnnotUri);
	      } # end-if there are some annotations
	  } # end-if there are annotations
      } # end-foreach servUri
  } # end-foreach servName
} # end-sub getjustOne_annotation_uri


################################################################
# add_servURIs_toList
################################################################
sub add_servURIs_toList {
  # Call: add_servURIs_toList(\%{$listServURIs},\%{$listURIs[$wfId]});

  # Parameters
  my %hashServ = %{(shift)};
  my %hashWf = %{(shift)};

  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $hashServ{$hashWf{$servName}{$servUri}{'opaqueURI'}}++;
      } # end-foreach service
  } # end-foreach workflow

  return(%hashServ);
} # end-sub add_servURIs_toList


################################################################
# print_arrayHashAnnot
################################################################
sub print_arrayHashAnnot(\@) {
  # IMPORTANT: In biomart and Rshell, hash id 'servUri' and $list[$wfId]{$servName}{$servUri}{'URI'} haven't the same value!!!!!!!!
  # Parameters
  my @list = @{(shift)};

  my $lastIndex = $#list;
  
  my $wfId=1;
  while($wfId <= $lastIndex){
      print("Wf$wfId:\n");
      foreach my $servName (keys %{$list[$wfId]}){
	  foreach my $servUri (keys %{$list[$wfId]{$servName}}){
	      print("\t$servName\t$list[$wfId]{$servName}{$servUri}{'type'}\t$list[$wfId]{$servName}{$servUri}{'URI'}\n");
	      for my $termUri (@{$list[$wfId]{$servName}{$servUri}{'annot'}}){
		  print("\t\t$termUri\n");
	      } # end-for annotation
	  } # end-foreach servUri
      } # end-foreach servName
      $wfId=$wfId+1;
  } # end-while wfId
} # end-sub print_arrayHashAnnot


################################################################
# print_hashOneWf
################################################################
sub print_hashOneWfAndData {
  # Parameters
  my $dataHash = shift;
  my %hash = %{(shift)};

  print("print_hashOneWfAndData: dataHash: $dataHash\n");

  print("OPMW content:\n");
  foreach my $servName (keys %hash){
      foreach my $servUri (keys %{$hash{$servName}}){
	  print("\t$servName\t$hash{$servName}{$servUri}{'type'}\t$hash{$servName}{$servUri}{'URI'}\n");
	  for my $termUri (@{$hash{$servName}{$servUri}{'annot'}}){
	      print("\t\t$termUri\n");
	  } # end-for annotation
	  for my $uses (@{$hash{$servName}{$servUri}{'uses'}}){
	      print("\t\t'USES' $uses\n");
	  } # end-for uses
      } # end-foreach servUri
  } # end-foreach servName

  print("\tDATA generated by:\n");
  for my $data (keys $dataHash){
      print("\t\t$data\n");
  } # end-foreach data

  return;
} # end-sub print_arrayHashAnnot


################################################################
# print_annotation_per_workflow_ttl
################################################################
sub print_annotation_per_workflow_ttl{
  # Use: print_annotation_per_workflow_ttl($wfId,$fileOut,$dataHash,$wfHash);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $dataHash = shift;
  my %hashWf = %{(shift)};

  my ($cont, $processName, $uriName, $opaqueURI, $type, $typeText);
 
  # First: To generate random data identifier
  # To generate data identifier in a randow way. With the structure: http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf0000/dataXX
  # If the name of the parameter/port (after ':') is the same, the random data generated must be the same, else a different one. Since each data with differente value after ':' has a different position in the hash, we only need to loop the hash.  
  $cont=1;
  for my $data (keys $dataHash){
      $dataHash->{$data}="http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf".$wfId."/data".$cont;
      $cont=$cont+1;
  } # end-foreach data
  
  # Second: To write file header and 'isGeneratedBy' sentences
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "\@prefix opmw: <http://www.opmw.org/ontology/> .\n\n");
  print(OUT "\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#/> .\n\n");

  for my $data (keys $dataHash){  
      print(OUT "<$dataHash->{$data}>\n");
      print(OUT "\ta opmw:DataVariable, opmw:WorkflowTemplateArtifact;\n");
      $processName=(split("\:",$data))[0];
      $uriName=(split("\:URI\:",$data))[1];
      $opaqueURI=$hashWf{$processName}{$uriName}{'opaqueURI'};
      print(OUT "\topmw:isGeneratedBy <$opaqueURI> ;\n");
      print(OUT "\t<opmw:isVariableOfTemplate <http://myexperiment.org/workflows/$wfId.xml> .\n\n"); # link to workflow
  } # end-foreach data

  # Third: To write each process information
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $type=$hashWf{$servName}{$servUri}{'type'};
	  if(($type eq "workflow") || ($type eq "dataflow.DataflowActivity")){
	      $typeText="nestedWorkflow";
	  }elsif(($type eq "Rshell") || ($type eq "rshell.RshellActivity")){
	      $typeText="rshell";
	  }elsif(($type eq "BioMart") || ($type eq "biomart.BiomartActivity")){
	      $typeText="BioMart";
	  }elsif(($type eq "Soap") || ($type eq "soaplab.SoaplabActivity")){
	      $typeText="SOAP";
	  }elsif(($type eq "wsdl") || ($type eq "wsdl.WSDLActivity")){
	      $typeText="WSDL";
	  }elsif($type eq "rest.RESTActivity"){
	      $typeText="REST";
	  }elsif(($type eq "BioMoby") || ($type eq "biomoby.BiomobyActivity")){
	      $typeText="BioMoby";
	  } # end-elsif nested

	  print(OUT "<$hashWf{$servName}{$servUri}{'opaqueURI'}>\n");
	  print(OUT "\trdfs:label $servName, $typeText, ");	  
	  if($typeText eq "REST"){
	      # To escape the uri, to avoid problems
	      print(OUT uri_escape($hashWf{$servName}{$servUri}{'URI'}));
	  }else{
	      print(OUT $hashWf{$servName}{$servUri}{'URI'});
	  }
	  print(OUT " ;\n");
	  
	  print(OUT "\ta opmw:WorkflowTemplateProcess");
	  if(defined (@{$hashWf{$servName}{$servUri}{'annot'}})){
	      if(scalar (@{$hashWf{$servName}{$servUri}{'annot'}}) > 0){
		  for my $termUri (@{$hashWf{$servName}{$servUri}{'annot'}}){
		      print(OUT ", <$termUri>");
		  } # end-for annotation
		  print(OUT " ;\n");
	      } # end-if there are annotations
	  } # end-if defined array 'annot'

	  for my $uses (@{$hashWf{$servName}{$servUri}{'uses'}}){	  
	      print(OUT "\topmw:uses <$dataHash->{$uses}> ;\n");
	  } # end-for uses

	  print(OUT "\topmw:isStepOfTemplate <http://myexperiment.org/workflows/$wfId.xml> .\n"); # link to workflow
	  print(OUT "\n");
      } # end-foreach servUri
  } # end-foreach servName

  close(OUT);
} # end sub print_annotation_per_workflow_ttl


################################################################
# print_annotation_per_workflow_rdf
################################################################
sub print_annotation_per_workflow_rdf{
  # Use: print_annotation_per_workflow_rdf($wfId,$fileOut,$dataHash,$wfHash);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $dataHash = shift;
  my %hashWf = %{(shift)};

  my ($cont, $processName, $uriName, $processURL, $opaqueURI, $type, $typeText, $uriPrint);
 
  # First: To generate random data identifier
  # To generate data identifier in a randow way. With the structure: http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf0000/dataXX
  # If the name of the parameter/port (after ':') is the same, the random data generated must be the same, else a different one. Since each data with differente value after ':' has a different position in the hash, we only need to loop the hash.  
  $cont=1;
  for my $data (keys $dataHash){
      $dataHash->{$data}="http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf".$wfId."/data".$cont;
      $cont=$cont+1;
  } # end-foreach data
  
  # Second: To write file header and 'isGeneratedBy' sentences
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "<?xml version=\"1.0\"?>\n");
  print(OUT "<rdf:RDF xmlns:opmw=\"http://www.opmw.org/ontology/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" >\n");
  for my $data (keys $dataHash){  
      $processName=(split("\:",$data))[0];
      $uriName=(split("\:URI\:",$data))[1];
      $processURL=$hashWf{$processName}{$uriName}{'URI'};
      $opaqueURI=$hashWf{$processName}{$uriName}{'opaqueURI'};
      
      print(OUT "\t<opmw:DataVariable rdf:about=\"$dataHash->{$data}\">\n");
      print(OUT "\t\t<rdf:type rdf:resource=\"http://www.opmw.org/ontology/WorkflowTemplateArtifact\" />\n");
      print(OUT "\t\t<opmw:isGeneratedBy rdf:resource=\"$opaqueURI\" />\n");
      print(OUT "\t\t<opmw:isVariableOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
      print(OUT "\t</opmw:DataVariable>\n\n");      
  } # end-foreach data

  # Third: To write each process information
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $type=$hashWf{$servName}{$servUri}{'type'};
	  if(($type eq "workflow") || ($type eq "dataflow.DataflowActivity")){
	      $typeText="nestedWorkflow";
	  }elsif(($type eq "Rshell") || ($type eq "rshell.RshellActivity")){
	      $typeText="rshell";
	  }elsif(($type eq "BioMart") || ($type eq "biomart.BiomartActivity")){
	      $typeText="BioMart";
	  }elsif(($type eq "Soap") || ($type eq "soaplab.SoaplabActivity")){
	      $typeText="SOAP";
	  }elsif(($type eq "wsdl") || ($type eq "wsdl.WSDLActivity")){
	      $typeText="WSDL";
	  }elsif($type eq "rest.RESTActivity"){
	      $typeText="REST";
	  }elsif(($type eq "BioMoby") || ($type eq "biomoby.BiomobyActivity")){
	      $typeText="BioMoby";
	  } # end-elsif nested

	  print(OUT "\t<opmw:WorkflowTemplateProcess rdf:about=\"$hashWf{$servName}{$servUri}{'opaqueURI'}\">\n");
	  print(OUT "\t\t<rdfs:label>$servName</rdfs:label>\n");
	  print(OUT "\t\t<rdfs:label>$typeText</rdfs:label>\n");
	  if($typeText eq "REST"){
	      # To escape the uri, to avoid problems
	      $uriPrint=uri_escape($hashWf{$servName}{$servUri}{'URI'});
	  }else{
	      $uriPrint=$hashWf{$servName}{$servUri}{'URI'};
	  }  
	  print(OUT "\t\t<rdfs:label>$uriPrint</rdfs:label>\n");  # Original URI as label.
          #   print(OUT "\t\t<rdf:type rdf:resource=\"$uriPrint\" />\n"); # Original URI as type.

	  if(scalar (@{$hashWf{$servName}{$servUri}{'annot'}}) > 0){
	      for my $termUri (@{$hashWf{$servName}{$servUri}{'annot'}}){
		  print(OUT "\t\t<rdf:type rdf:resource=\"$termUri\" />\n");
	      } # end-for annotation
	  } # end-if there are annotations
	  
	  for my $uses (@{$hashWf{$servName}{$servUri}{'uses'}}){
	      print(OUT "\t\t<opmw:uses rdf:resource=\"$dataHash->{$uses}\" />\n"); # link to workflow
	  } # end-for uses
	  
	  print(OUT "\t\t<opmw:isStepOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
	  print(OUT "\t</opmw:WorkflowTemplateProcess>\n");
	  print(OUT "\n");
      } # end-foreach servUri
  } # end-foreach servName

  print(OUT "</rdf:RDF>\n");
  close(OUT);
} # end sub print_annotation_per_workflow_rdf


################################################################
# print_annotation_per_workflow_rdf_justTypeServ
################################################################
sub print_annotation_per_workflow_rdf_justTypeServ{
  # Use: print_annotation_per_workflow_justTypeServ($wfId,$fileOut,$dataHash,$wfHash);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $dataHash = shift;
  my %hashWf = %{(shift)};

  my ($cont, $processName, $uriName, $processURL, $opaqueURI, $type, $typeText, $uriPrint);
 
  # First: To generate random data identifier
  # To generate data identifier in a randow way. With the structure: http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf0000/dataXX
  # If the name of the parameter/port (after ':') is the same, the random data generated must be the same, else a different one. Since each data with differente value after ':' has a different position in the hash, we only need to loop the hash.  
  $cont=1;
  for my $data (keys $dataHash){
      $dataHash->{$data}="http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf".$wfId."/data".$cont;
      $cont=$cont+1;
  } # end-foreach data
  
  # Second: To write file header and 'isGeneratedBy' sentences
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "<?xml version=\"1.0\"?>\n");
  print(OUT "<rdf:RDF xmlns:opmw=\"http://www.opmw.org/ontology/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" >\n");
  for my $data (keys $dataHash){  
      $processName=(split("\:",$data))[0];
      $uriName=(split("\:URI\:",$data))[1];
      $processURL=$hashWf{$processName}{$uriName}{'URI'};
      $opaqueURI=$hashWf{$processName}{$uriName}{'opaqueURI'};
      
      print(OUT "\t<opmw:DataVariable rdf:about=\"$dataHash->{$data}\">\n");
      print(OUT "\t\t<rdf:type rdf:resource=\"http://www.opmw.org/ontology/WorkflowTemplateArtifact\" />\n");
      print(OUT "\t\t<opmw:isGeneratedBy rdf:resource=\"$opaqueURI\" />\n");
      print(OUT "\t\t<opmw:isVariableOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
      print(OUT "\t</opmw:DataVariable>\n\n");      
  } # end-foreach data

  # Third: To write each process information
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $type=$hashWf{$servName}{$servUri}{'type'};
	  if(($type eq "workflow") || ($type eq "dataflow.DataflowActivity")){
	      $typeText="nestedWorkflow";
	  }elsif(($type eq "Rshell") || ($type eq "rshell.RshellActivity")){
	      $typeText="rshell";
	  }elsif(($type eq "BioMart") || ($type eq "biomart.BiomartActivity")){
	      $typeText="BioMart";
	  }elsif(($type eq "Soap") || ($type eq "soaplab.SoaplabActivity")){
	      $typeText="SOAP";
	  }elsif(($type eq "wsdl") || ($type eq "wsdl.WSDLActivity")){
	      $typeText="WSDL";
	  }elsif($type eq "rest.RESTActivity"){
	      $typeText="REST";
	  }elsif(($type eq "BioMoby") || ($type eq "biomoby.BiomobyActivity")){
	      $typeText="BioMoby";
	  } # end-elsif nested

	  print(OUT "\t<opmw:WorkflowTemplateProcess rdf:about=\"$hashWf{$servName}{$servUri}{'opaqueURI'}\">\n");
	  print(OUT "\t\t<rdfs:label>$servName</rdfs:label>\n");
	  if($typeText eq "REST"){
	      # To escape the uri, to avoid problems
	      $uriPrint=uri_escape($hashWf{$servName}{$servUri}{'URI'});
	  }else{
	      $uriPrint=$hashWf{$servName}{$servUri}{'URI'};
	  }  
	  print(OUT "\t\t<rdfs:label>$uriPrint</rdfs:label>\n");  # Original URI as label.

	  # The unique rdf-type is the category of service.
          print(OUT "\t\t<rdf:type rdf:resource=\"$typeText\" />\n");
	  
	  # Without ontological annotations!!!!!!

	  for my $uses (@{$hashWf{$servName}{$servUri}{'uses'}}){
	      print(OUT "\t\t<opmw:uses rdf:resource=\"$dataHash->{$uses}\" />\n"); # link to workflow
	  } # end-for uses
	  
	  print(OUT "\t\t<opmw:isStepOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
	  print(OUT "\t</opmw:WorkflowTemplateProcess>\n");
	  print(OUT "\n");
      } # end-foreach servUri
  } # end-foreach servName

  print(OUT "</rdf:RDF>\n");
  close(OUT);
} # end sub print_annotation_per_workflow_rdf_justTypeServ


################################################################
# print_annotation_per_workflow_rdf_justURIserv
################################################################
sub print_annotation_per_workflow_rdf_justURIserv{
  # Use: print_annotation_per_workflow_rdf_justURIserv($wfId,$fileOut,$dataHash,$wfHash);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $dataHash = shift;
  my %hashWf = %{(shift)};

  my ($cont, $processName, $uriName, $processURL, $opaqueURI, $type, $typeText, $uriPrint);
 
  # First: To generate random data identifier
  # To generate data identifier in a randow way. With the structure: http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf0000/dataXX
  # If the name of the parameter/port (after ':') is the same, the random data generated must be the same, else a different one. Since each data with differente value after ':' has a different position in the hash, we only need to loop the hash.  
  $cont=1;
  for my $data (keys $dataHash){
      $dataHash->{$data}="http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf".$wfId."/data".$cont;
      $cont=$cont+1;
  } # end-foreach data
  
  # Second: To write file header and 'isGeneratedBy' sentences
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "<?xml version=\"1.0\"?>\n");
  print(OUT "<rdf:RDF xmlns:opmw=\"http://www.opmw.org/ontology/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" >\n");
  for my $data (keys $dataHash){  
      $processName=(split("\:",$data))[0];
      $uriName=(split("\:URI\:",$data))[1];
      $processURL=$hashWf{$processName}{$uriName}{'URI'};
      $opaqueURI=$hashWf{$processName}{$uriName}{'opaqueURI'};
      
      print(OUT "\t<opmw:DataVariable rdf:about=\"$dataHash->{$data}\">\n");
      print(OUT "\t\t<rdf:type rdf:resource=\"http://www.opmw.org/ontology/WorkflowTemplateArtifact\" />\n");
      print(OUT "\t\t<opmw:isGeneratedBy rdf:resource=\"$opaqueURI\" />\n");
      print(OUT "\t\t<opmw:isVariableOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
      print(OUT "\t</opmw:DataVariable>\n\n");      
  } # end-foreach data

  # Third: To write each process information
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $type=$hashWf{$servName}{$servUri}{'type'};
	  if(($type eq "workflow") || ($type eq "dataflow.DataflowActivity")){
	      $typeText="nestedWorkflow";
	  }elsif(($type eq "Rshell") || ($type eq "rshell.RshellActivity")){
	      $typeText="rshell";
	  }elsif(($type eq "BioMart") || ($type eq "biomart.BiomartActivity")){
	      $typeText="BioMart";
	  }elsif(($type eq "Soap") || ($type eq "soaplab.SoaplabActivity")){
	      $typeText="SOAP";
	  }elsif(($type eq "wsdl") || ($type eq "wsdl.WSDLActivity")){
	      $typeText="WSDL";
	  }elsif($type eq "rest.RESTActivity"){
	      $typeText="REST";
	  }elsif(($type eq "BioMoby") || ($type eq "biomoby.BiomobyActivity")){
	      $typeText="BioMoby";
	  } # end-elsif nested

	  print(OUT "\t<opmw:WorkflowTemplateProcess rdf:about=\"$hashWf{$servName}{$servUri}{'opaqueURI'}\">\n");
	  print(OUT "\t\t<rdfs:label>$servName</rdfs:label>\n");
          print(OUT "\t\t<rdfs:label>$typeText</rdfs:label>\n");

	  if($typeText eq "REST"){
	      # To escape the uri, to avoid problems
	      $uriPrint=uri_escape($hashWf{$servName}{$servUri}{'URI'});
	  }else{
	      $uriPrint=$hashWf{$servName}{$servUri}{'URI'};
	  }  
	  # The unique rdf-type is the original URI of the service.
          print(OUT "\t\t<rdf:type rdf:resource=\"$uriPrint\" />\n");  # Original URI as type
	  
	  # Without ontological annotations!!!!!!

	  for my $uses (@{$hashWf{$servName}{$servUri}{'uses'}}){
	      print(OUT "\t\t<opmw:uses rdf:resource=\"$dataHash->{$uses}\" />\n"); # link to workflow
	  } # end-for uses
	  
	  print(OUT "\t\t<opmw:isStepOfTemplate rdf:resource=\"http://myexperiment.org/workflows/$wfId.xml\" />\n"); # link to workflow
	  print(OUT "\t</opmw:WorkflowTemplateProcess>\n");
	  print(OUT "\n");
      } # end-foreach servUri
  } # end-foreach servName

  print(OUT "</rdf:RDF>\n");
  close(OUT);
} # end sub print_annotation_per_workflow_rdf_justURIserv


################################################################
# print_gvFile
################################################################
sub print_gvFile{
  # Use: print_gvFile($wfId,$fileOut,$fileDatalinks,$wfHash);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $fileDatalinks = shift;
  my %hashWf = %{(shift)};

  my ($sourceProcessName, $type, $colorServ, $printName, $printNameSink, $printNameSource, $sourceUriName, $idService);
  my $countServices=0;
  my $countLinks=0;
 
  # To write file header
  open(LINK,">$fileDatalinks") or die "Couldn't open: $fileDatalinks";
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "digraph wf".$wfId."{\n");

  # To write services names (although it isn't need if all of them have links.).
  print(OUT "\t/*nodes names. To be sure all services appear, although it hasn't links.*/\n");
  print(OUT "\tnode [shape=box,color=black];\n"); 
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $countServices=$countServices+1;
	  # Colors from Taverna [http://dev.mygrid.org.uk/wiki/display/tav250/Workflow+Diagram] vs Graphviz [http://www.graphviz.org/doc/info/colors.html]
	  $type=$hashWf{$servName}{$servUri}{'type'};
	  $colorServ="white";
	  if(($type eq "workflow") || ($type eq "dataflow.DataflowActivity")){
	      $colorServ="lightpink";
	  }elsif(($type eq "Rshell") || ($type eq "rshell.RshellActivity")){
	      $colorServ="cadetblue"; # dark blue
	  }elsif(($type eq "BioMart") || ($type eq "biomart.BiomartActivity")){
	      $colorServ="powderblue"; # light blue
	  }elsif(($type eq "Soap") || ($type eq "soaplab.SoaplabActivity")){
	      $colorServ="lightgoldenrodyellow"; # light yellow
	  }elsif(($type eq "wsdl") || ($type eq "wsdl.WSDLActivity")){
	      $colorServ="yellowgreen"; # spring green
	  }elsif($type eq "rest.RESTActivity"){
	      $colorServ="skyblue";
	  }elsif(($type eq "BioMoby") || ($type eq "biomoby.BiomobyActivity")){
	      $colorServ="orange";
	  } # end-elsif nested

	  $idService=(split("\/serv",$hashWf{$servName}{$servUri}{'opaqueURI'}))[1]; # Format opaqueUri: "http://www.wilkinsonlab.info/myExperiment_Annotations/workflowTemplateProcess/wf".$wfId."/serv".$contServices;
	  $printName="\"".$idService.":".$servName."\"";
#	  if(($servName =~ "-") || ($servName =~ "\\(") || ($servName =~ "\\.")){
#  	      $printName="\"".$servName."\"";
# 	  }
	  $hashWf{$servName}{$servUri}{'gvID'}=$printName;
	  print(OUT "\t$printName [style=filled,fillcolor=$colorServ,URL=\"$hashWf{$servName}{$servUri}{'URI'}\"];\n");
      } # end-foreach servUri
  } # end-foreach servName
  print(OUT "\n");

  # Third: To write each link from 'uses' info
  foreach my $servName (keys %hashWf){
      foreach my $servUri (keys %{$hashWf{$servName}}){
	  $printNameSink=$hashWf{$servName}{$servUri}{'gvID'};
	  for my $uses (@{$hashWf{$servName}{$servUri}{'uses'}}){
	      $countLinks=$countLinks+1;
	      $sourceProcessName=(split("\:",$uses))[0];
	      $sourceUriName=(split("\:URI\:",$uses))[1];
	      $printNameSource=$hashWf{$sourceProcessName}{$sourceUriName}{'gvID'};
	      print(OUT "\t$printNameSource -> $printNameSink;\n");
	      print(LINK "$sourceProcessName:URI:$hashWf{$sourceProcessName}{$sourceUriName}{'URI'} -> $servName:URI:$hashWf{$servName}{$servUri}{'URI'}\n");
	  } # end-for uses
      } # end-foreach servUri
  } # end-foreach servName

  print(OUT "}\n");
  close(OUT);
  close(LINK);

  print("\t$countServices\t$countLinks");
} # end sub print_gvFile


################################################################
# sub obtain_URL_MOBY REAL!!!!!!!
################################################################
sub obtain_URL_MOBY($){
  # Parameters
  my ($nameServ) = @_;

  my $bioMobyDescURL = "http://moby.ucalgary.ca/cgi-bin/getServiceDescription";
  my $parser = XML::LibXML->new(recover => 2);

  my $url_sub="";
  my $href="";
  my ($doc, $root, $service);
  my @line;
   
  $doc = $parser->load_html(location => $bioMobyDescURL);
  $root = XML::LibXML::XPathContext->new($doc);
  if(($root->findnodes('/descendant::a[contains(@href,'."'$nameServ'".')]'))->size > 0){
      $service = ($root->findnodes('/descendant::a[contains(@href,'."'$nameServ'".')]'))[0];
      $href=$service->findvalue('@href');
      
      $doc = $parser->load_html(location => $href);

      @line = split('<br>|<br \/>|<br\/>',$doc->toString);
      $url_sub = (grep(/<b>Endpoint:<\/b>/,@line))[0]; # [0]: There is only 1 element <b>Endpoint</b>
      $url_sub =~ s/<b>Endpoint:<\/b>//;
  }
  
  return($url_sub);
}


################################################################
# sub obtain_URL_MOBY_current: when ucalgary.ca doesn't work. Take into account that the number of parameter is different!!!!
################################################################
sub obtain_URL_MOBY_current($$){
  # Parameters
  my $nameServ = shift;
  my $idWf = shift;

  my $filePairsNameServURL = "$ARGV[1]/wf_service_type_URI_annotation.txt";

  my $url_sub="";
  my $line;

  chomp($line = qx!egrep "$idWf\t$nameServ" $filePairsNameServURL | head -n1 !);
  $url_sub = (split('\t',$line))[3];

  return($url_sub);
}


###################################################################################
# get_dataflowRef(name,uri,wfId,dataStructure,hash)
###################################################################################
sub get_dataflowRef{
   my $name = shift;
   my $uri = shift;
   my $wfId = shift;
   my $dataStructureRoot = shift; 
   my %hashWf = %{(shift)};

   my ($node, $ref, $found, @nodes, $uriTemp);

   @nodes = ($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow/ns:processors/ns:processor[ns:name=\''.$name.'\']/ns:activities/ns:activity/ns:configBean/ns:dataflow'));
   $found=0;
   while(($node = shift(@nodes)) && ($found==0)){
       $uriTemp = get_uri_currentNode_t2flow($node,$wfId);
       if($uriTemp eq $uri){
	   $found=1;
	   $ref=$node->getAttribute("ref");
	   #print("DataflowRef inside: $ref\n");
	   $hashWf{$name}{$uri}{'dataflowRef'}=$ref;
       } # end-if
   } # end-while
   
   return;
} # end-sub get_dataflowRef


###################################################################################
# get_uri_currentNode_scufl(node)
###################################################################################
sub get_uri_currentNode_scufl{
   # Parameters 
   my $node = shift;
   my $wfId = shift;

   my ($uri, $wsdlNode, $idNestedWf, $operation);

   $uri="";
   $operation="";

   if ($node->exists('s:arbitrarywsdl')){       
       $wsdlNode = ($node->getChildrenByTagName("s:arbitrarywsdl"))[0];
       $uri=($wsdlNode->getChildrenByTagName("s:wsdl"))[0]->textContent;
       $operation=($wsdlNode->getChildrenByTagName("s:operation"))[0]->textContent;
       if($operation ne ""){
	   $uri=$uri."#".$operation;
       }
   }elsif($node->exists('s:biomart')){
       $uri="http://www.biomart.org/biomart/martservice";
   }elsif(($node->exists('s:biomobyparser')) || ($node->exists('s:biomobyobject')) || ($node->exists('s:biomobywsdl'))){
       # There are several endpoints (<s:biomobyparser>/<s:endpoint>, s:biomobyobject><s:mobyEndpoint)>
       # Available description is already got from s:description + @name. No more text available, because the description in 'http://moby.ucalgary.ca/cgi-bin/getServiceDescription' (used in t2flow) is the same that in the scufl file.
       $uri=obtain_URL_MOBY_current($node->getAttribute("name"),$wfId);
       if($uri eq ""){
	   if($node->exists('s:biomobyparser')){
	       $uri = ($node->getElementsByTagName("s:endpoint"))[0]->textContent;
	   }elsif(($node->exists('s:biomobyobject')) || ($node->exists('s:biomobywsdl'))){
	       $uri = ($node->getElementsByTagName("s:mobyEndpoint"))[0]->textContent;
	   }
       } #end-if URI==""
   }elsif($node->exists('s:soaplabwsdl')){
       $uri = ($node->getChildrenByTagName("s:soaplabwsdl"))[0]->textContent;
   }elsif($node->exists('s:rshell')){
       $uri="http://rshellservice";
   }elsif($node->exists('s:workflow')){
       if(($node->getElementsByTagName("s:xscufllocation"))->size > 0){
	   $uri=($node->getElementsByTagName("s:xscufllocation"))[0]->textContent;
       }else{
	   $idNestedWf = ($node->getElementsByTagName("s:workflowdescription"))[0]->getAttribute("lsid");
	   $uri="http://www.myexperiment.org/workflows/$wfId/$idNestedWf";
       } # end-if s:xscufllocation
   } # end-if case service type

   return($uri);
} # end sub get_uri_currentNode_scufl


###################################################################################
# get_uri_currentNode_t2flow(node)
###################################################################################
sub get_uri_currentNode_t2flow{
   # Parameters 
   my $node = shift;
   my $wfId = shift;

   my ($uri, $wsdlNode, $idNestedWf, $operation);
   my ($class, $servType, $headerClass, $parent);

   $uri="";
   $operation="";

   #print("Node in get_uri_T2flow: ".$node->textContent."\n");
   #print("Node in get_uri_T2flow: ".($node->getChildrenByTagName("name"))[0]->textContent."\n");
   $class = ((((($node->getChildrenByTagName("activities"))[0])->getChildrenByTagName("activity"))[0])->getChildrenByTagName("class"))[0]; # Whole path: ns:activities/ns:activity/ns:class
   $servType=$class->textContent;
   $headerClass="net.sf.taverna.t2.activities.";
   $servType =~ s/$headerClass//;

   if($servType eq "wsdl.WSDLActivity") {
       # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
       $parent=$class->parentNode;
       $uri= (($parent->getElementsByTagName("wsdl"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.wsdl.WSDLActivityConfigurationBean/wsdl
       $operation=(($parent->getElementsByTagName("operation"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.wsdl.WSDLActivityConfigurationBean/operation
       if($operation ne ""){
	   $uri=$uri."#".$operation;
       }
   }elsif(index($servType,"biomart") > -1){
       # biomart.BiomartActivity
       $uri="http://www.biomart.org/biomart/martservice";
   }elsif(index($servType,"biomoby.BiomobyActivity") > -1){	
       # biomoby.BiomobyActivity  <-- We only have annotations for these ones, neither for Object nor for DatatypeActivity (biomoby.BiomobyObjectActivity, biomoby.MobyParseDatatypeActivity).
       # To search description in 'http://moby.ucalgary.ca/cgi-bin/getServiceDescription'
       $uri=obtain_URL_MOBY_current(($node->getChildrenByTagName("name"))[0]->textContent,$wfId);
   }elsif(index($servType,"soaplab") > -1){
       # soaplab.SoaplabActivity
       # CHECK WITH service no.5 in output_16.t2flow and wf_myExperiment_2226_withoutShims.t2flow (many soap services!)
       # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
       $parent=$class->parentNode;
       # URL=processor/activities/configBean/
       $uri= (($parent->getElementsByTagName("endpoint"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.soaplab.SoaplabActivityConfigurationBean/endPoint
   }elsif(index($servType,"rshell") > -1){
       # rshell.RshellActivity
       $uri="http://rshellservice";
   }elsif(index($servType,"rest.RESTActivity") > -1){
       # rest.RESTActivity
       # CHECK WITH wf_myExperiment_1510_withoutShims.t2flow
       # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
       $parent=$class->parentNode;
       # URL=processor/activities/configBean/
       $uri= (($parent->getElementsByTagName("urlSignature"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.rest.RESTActivityConfigurationBean/urlSignature
   }elsif($servType eq "dataflow.DataflowActivity") {
       $parent=$class->parentNode;
       $idNestedWf=((($parent->getElementsByTagName("configBean"))[0])->getChildrenByTagName("dataflow"))[0]->getAttribute("ref");
       $uri="http://www.myexperiment.org/workflows/$wfId/$idNestedWf";
   }

   return($uri);
} # end sub get_uri_currentNode_t2flow


###################################################################################
# simpleServiceSink(wfId,nodeName,dataName,uriName,idA,dataStructure,linksAtoB,@list) [recursive]
###################################################################################
sub simpleServiceSink{
   # Parameters 
   my $wfId = shift;
   my $nodeName = shift;
   my $dataName = shift;
   my $uriName = shift;
   my $idA = shift;
   my $dataStructureRoot = shift; 
   my $dataGenBy = shift;
   my %hashWf = %{(shift)};

#    print("1.-wfId:$wfId\n");
#     print("2.-nodeName:$nodeName\n");
#     print("3.-dataName:$dataName\n");
#     print("4.-uriName:$uriName\n");
#     print("5.-identifier:$idA\n");
#    print("6.-dataStructureRoot:$dataStructureRoot\n");
#    print("7.-dataGenBy: $dataGenBy\n");
#    print("8.-hashWf: %hashWf\n");
  
   my ($queryProcessorName, $node, $datalink, $linkToServiceNotOutput);
   my ($pB,$nameB,$dataB,$uriB);
   my ($found, $foundB, @nodes_name, @nodes_nameB, $uriTemp, $parent, $nodeB, $currentName, $matched);

   $queryProcessorName='/descendant::s:processor[@name=\''.$nodeName.'\']';
   #$node = ($dataStructureRoot->findnodes($queryProcessorName))[0]; 
   $found=0;
   @nodes_name=$dataStructureRoot->findnodes($queryProcessorName);
   while(($node = shift(@nodes_name)) && ($found==0)){
       $uriTemp = get_uri_currentNode_scufl($node,$wfId);
       if($uriTemp eq $uriName){
	   $found=1;
	   foreach $datalink ($node->getElementsByTagName("s:link")){
	       if($datalink->getAttribute("source") eq "$dataName" ){	   
		   $pB=$datalink->getAttribute("sink");
		   #print("pB: $pB\n");
		   $linkToServiceNotOutput=($pB =~ ":");	  
		   $nameB=(split("\:",$pB))[0];
		   if($linkToServiceNotOutput == 1){
		       # If it isn't a service, it's a direct link to Output, not to service. Not interest on it.
		       # URI_B:
		       $foundB=0;
		       @nodes_nameB=$node->getElementsByTagName("s:processor");
		       while(($nodeB = shift(@nodes_nameB)) && ($foundB==0)){
			   #print("nameB: $nameB\n");
			   #print("nodeB: ".$nodeB->textContent."\n");
			   $currentName=$nodeB->getAttribute("name");
			   #print("currentName: $currentName\n");
			   if($currentName eq $nameB){
			       $foundB=1;
			       $uriB = get_uri_currentNode_scufl($nodeB,$wfId);			   
			   } # end-if nodeB found
		       } # end-while looking for URI B

		       if(defined($hashWf{$nameB}{$uriB})) {
			   if(($hashWf{$nameB}{$uriB}{'type'}) ne 'workflow'){# Base case  ### In T2flow: dataflo.DataflowActivity
			       if(!defined $dataGenBy->{$idA}){
				   $dataGenBy->{$idA}++;
				   #print("New data (sink)!!!: $idA\n");
			       } # end-if not repeated GeneratedBy
			       #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
			       $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
			       if($matched == 0){				       
				   push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
				   #print("Push uses: $idA->$nameB:$dataB:URI:uriB\n");
			       } # end-if not repeated uses
			   }else{
			       $dataB=(split("\:",$pB))[1];
			       simpleServiceSink($wfId,$nameB,$dataB,$uriB,$idA,$dataStructureRoot,$dataGenBy,\%hashWf);
			   } # end-if B==nestedWf
		       } # end-if B defined
		   } # end-if B is service (linkToServiceNotOutput == 1)
	       } # end-if datalink with source EQUAL TO dataName
	   } # end-foreach datalink
       } # end-if uriName==uriTemp
   } # end-while $node with the same name
    return;       
} # end-sub simpleServiceSink


###################################################################################
# simpleServiceSource(wfId,nodeName,dataName,uriName,idB,dataStructure,linksAtoB,@list) [recursive]
###################################################################################
sub simpleServiceSource{
   # Parameters 
   my $wfId = shift;
   my $nodeName = shift;
   my $dataName = shift;
   my $uriName = shift;
   my $idB = shift;
   my $dataStructureRoot = shift; 
   my $dataGenBy = shift;
   my %hashWf = %{(shift)};

#    print("1.-wfId:$wfId\n");
#     print("2.-nodeName:$nodeName\n");
#     print("3.-dataName:$dataName\n");
#     print("4.-uriName:$uriName\n");
#     print("5.-identifierB:$idB\n");
#    print("6.-dataStructureRoot:$dataStructureRoot\n");
#    print("7.-dataGenBy: $dataGenBy\n");
#    print("8.-hashWf: %hashWf\n");

   my ($queryProcessorName, $node, $datalink, $linkFromServiceNotInput);
   my ($pA,$nameA,$dataA,$pB,$nameB,$dataB);

   my ($found, $foundA, @nodes_name, @nodes_nameA, $uriTemp, $parent, $nodeA, $idA, $uriA, $uriB, $currentName, $matched);

   $queryProcessorName='/descendant::s:processor[@name=\''.$nodeName.'\']';

   #$node = ($dataStructureRoot->findnodes($queryProcessorName))[0]; 
   $found=0;
   @nodes_name=$dataStructureRoot->findnodes($queryProcessorName);
   while(($node = shift(@nodes_name)) && ($found==0)){
       $uriTemp = get_uri_currentNode_scufl($node,$wfId);
       if($uriTemp eq $uriName){
	   $found=1;
	   foreach $datalink ($node->getElementsByTagName("s:link")){
	       if($datalink->getAttribute("sink") eq "$dataName" ){
		   $pA=$datalink->getAttribute("source");
		   #print("pa: $pA\n");
		   $linkFromServiceNotInput=($pA =~ ":");	  
		   $nameA=(split("\:",$pA))[0];
		   if($linkFromServiceNotInput == 1){
		       # If it isn't a service, it's a direct link to Input, not to service. Not interest on it.
		       # URI_A:		      
		       $foundA=0;		     
		       @nodes_nameA=$node->getElementsByTagName("s:processor");
		       while(($nodeA = shift(@nodes_nameA)) && ($foundA==0)){
			   #print("nameA: $nameA\n");
			   # print("nodeA: ".$nodeA->textContent."\n");
			   $currentName=$nodeA->getAttribute("name");
			   #print("currentName: $currentName\n");
			   if($currentName eq $nameA){
			       $foundA=1;
			       $uriA = get_uri_currentNode_scufl($nodeA,$wfId);			   
			   } # end-if nodeA found
		       } # end-while looking for URI A

		       if(defined($hashWf{$nameA}{$uriA})){
			   $idA=$pA.":URI:".$uriA;
			   #print("idA: $idA\n");
			   if(($hashWf{$nameA}{$uriA}{'type'}) eq 'workflow'){# Base case  ### In T2flow: dataflow.DataflowActivity
			       $dataA=(split("\:",$pA))[1];
			       simpleServiceSource($wfId,$nameA,$dataA,$uriA,$idB,$dataStructureRoot,$dataGenBy,\%hashWf);
			   }else{ # Base case
			       #pA with right value: to manage pB
			       #$pB=$processB;
			       $nameB=(split("\:",$idB))[0];
			       $uriB=(split("\:URI\:",$idB))[1];
			       #print("idB: $idB\n");
			       #print("uriB: $uriB\n");
			       if(($hashWf{$nameB}{$uriB}{'type'}) ne 'workflow'){  ### In T2flow: dataflow.DataflowActivity
				   
				   if(!defined $dataGenBy->{$idA}){
				       $dataGenBy->{$idA}++;
				       #print("New data (source)!!!: $idA\n");
				   } # end-if not repeated GeneratedBy
				   #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
				   $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
				   #print("matched: $matched\n");
				   if($matched == 0){				       
				       push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
				       #print("Push uses: $idA->$idB\n");
				   } # end-if not repeated uses
			       }else{
				   $dataB=(split("\:",$idB))[1];
				   simpleServiceSink($wfId,$nameB,$dataB,$uriB,$idA,$dataStructureRoot,$dataGenBy,\%hashWf);
			       } # end-if B==nestedWf
			   } # end-if A==nestedWf
		       } # end-if A is defined
		   } # end-if A is service (linkFromServiceNotInput == 1)
	       } # end-if datalink with sink EQUAL TO dataName
	   } # end-foreach datalink  
       } # end-if uriName==uriTemp
   } # end-while $node with the same name

   return;
} # end-sub-simpleServiceSource


###################################################################################
# simpleServiceSink_t2flow(wfId,nodeName,dataName,uriName,idA,dataStructure,linksAtoB,@list) [recursive]
###################################################################################
sub simpleServiceSink_t2flow{
   # Parameters 
   my $wfId = shift;
   my $nodeName = shift;
   my $dataName = shift;
   my $uriName = shift;
   my $idA = shift;
   my $dataStructureRoot = shift; 
   my $dataGenBy = shift;
   my %hashWf = %{(shift)};

#    print("1.-wfId:$wfId\n");
#     print("2.-nodeName:$nodeName\n");
#     print("3.-dataName:$dataName\n");
#     print("4.-uriName:$uriName\n");
#     print("5.-identifierA:$idA\n");
#    print("6.-dataStructure_root:$dataStructureRoot\n");
#    print("7.-dataGenBy: $dataGenBy\n");
#    print("8.-hashWf: %hashWf\n");
  
   my ($queryProcessorName,$node, $datalink, @datalinks, $linkToServiceNotOutput, @linkToServiceNotOutput_array, $dataflowRef);
   my ($pB,$nameB,$dataB, $found, @nodes_name, $uriTemp, $foundB, @nodes_nameB, $nodeB, $uriB, @uriString, $lengthUriString, $matched);

   @datalinks=();

   if(!(defined $hashWf{$nodeName}{$uriName}{'dataflowRef'})){      
      # get_dataflowRef($nodeName,$uriName,$wfId,$dataStructureRoot,\%hashWf); 
       @uriString=split(/\//,$hashWf{$nodeName}{$uriName}{'URI'});
       $lengthUriString=(scalar @uriString);
       $hashWf{$nodeName}{$uriName}{'dataflowRef'}=$uriString[$lengthUriString-1];
   }
   $dataflowRef=$hashWf{$nodeName}{$uriName}{'dataflowRef'};
   #print("DataflowRef fuera: $dataflowRef\n");

#    $found=0;
#    @nodes_name=($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']'));
#    while(($node = shift(@nodes_name)) && ($found==0)){
#        $uriTemp = get_uri_currentNode_t2flow($node,$wfId);
#        if($uriTemp eq $uriName){
# 	   $found=1;
# 	   @datalinks = ((($node->getChildrenByTagName("datalinks"))[0])->getChildrenByTagName("datalink"));

    @datalinks = ($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:datalinks/ns:datalink[ns:source/ns:port=\''.$dataName.'\']')); 
   foreach $datalink (@datalinks){
#	       if( (((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("port"))[0])->textContent eq $dataName ){ # Links associated to nameA as source.
       @linkToServiceNotOutput_array=((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("processor"));
       $linkToServiceNotOutput=(scalar @linkToServiceNotOutput_array);
       if($linkToServiceNotOutput == 1){ 
	   # If it isn't a service, it's a direct link to Output, not to service. Not interest on it.
	   $nameB=((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("processor"))[0]->textContent;
	   #print("nameB: $nameB\n");
	   #URI_B:
	   if(($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:processors/ns:processor[ns:name="'.$nameB.'"]'))->size > 0){
	       $nodeB=(($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:processors/ns:processor[ns:name="'.$nameB.'"]'))[0]);
	       $uriB = get_uri_currentNode_t2flow($nodeB,$wfId);
# 	   $foundB=0;
# 	   @nodes_nameB=$node->getChildrenByTagName("processor");
# 	   while(($nodeB = shift(@nodes_nameB)) && ($foundB==0)){
# 	       if( (($nodeB->getChildrenByTagName("name"))[0])->textContent eq $nameB){
# 		   $foundB=1;
# 		   $uriB = get_uri_currentNode_t2flow($nodeB,$wfId);
# 	       } # end-if nodeB found
# 	   } # end-while looking for URI B

	       if(defined($hashWf{$nameB}{$uriB})){		  
		   $dataB=((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("port"))[0]->textContent;
		   $pB=$nameB.":".$dataB;
		   if(($hashWf{$nameB}{$uriB}{'type'}) ne 'dataflow.DataflowActivity'){ # Base case 
		       if(!defined $dataGenBy->{$idA}){
			   $dataGenBy->{$idA}++;
			   #print("New data (sink)!!!: $idA\n");
		       } # end-if not repeated GeneratedBy
		       #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
		       $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
		       #print("matched: $matched\n");
		       if($matched == 0){
			   push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
			   #print("Push uses: $idA->$nameB:$dataB:URI:$uriB\n");
		       } # end-if not repeated uses
		   }else{
		       simpleServiceSink_t2flow($wfId,$nameB,$dataB,$uriB,$idA,$dataStructureRoot,$dataGenBy,\%hashWf);
		   } # end-if B==nestedWf
	       } # end-if B is service
	   } # if processor with nameB exists
       }  # end-if B is service (linkToServiceNotOutput == 1)
   } # end-foreach datalinks
# 	       } # end-if A is not linkFromServiceNotInput
# 	   } # end-if datalink with source is equal to nameA
#        } # end-if uriTemp==uriName
#    } # end-while $node with the same name
   return;       
} # end-sub simpleServiceSink_t2flow


###################################################################################
# simpleServiceSource_t2flow(wfId,nodeName,dataName,uriName,idB,dataStructure,linksAtoB,@list) [recursive]
###################################################################################
sub simpleServiceSource_t2flow{
   # Parameters 
   my $wfId = shift;
   my $nodeName = shift;
   my $dataName = shift;
   my $uriName = shift;
   my $idB = shift;
   my $dataStructureRoot = shift; 
   my $dataGenBy = shift;
   my %hashWf = %{(shift)};

#    print("1.-wfId:$wfId\n");
#     print("2.-nodeName:$nodeName\n");
#     print("3.-dataName:$dataName\n");
#     print("4.-uriName:$uriName\n");
#     print("5.-identifierB:$idB\n");
#    print("6.-dataStructureRoot:$dataStructureRoot\n");
#    print("7.-dataGenBy: $dataGenBy\n");
#    print("8.-hashWf: %hashWf\n");

   my ($queryProcessorName, $node, $datalink, @datalinks, $linkFromServiceNotInput, @linkFromServiceNotInput_array, $dataflowRef);
   my ($pA,$nameA,$dataA,$pB,$nameB,$dataB, $found, @nodes_name, $uriTemp, $foundA, @nodes_nameA, $nodeA, $uriA, $idA, $uriB, @uriString, $lengthUriString, $matched);
   @datalinks=();
   
   if(!(defined $hashWf{$nodeName}{$uriName}{'dataflowRef'})){
      # get_dataflowRef($nodeName,$uriName,$wfId,$dataStructureRoot,\%hashWf); 
       @uriString=split(/\//,$hashWf{$nodeName}{$uriName}{'URI'});
       $lengthUriString=(scalar @uriString);
       $hashWf{$nodeName}{$uriName}{'dataflowRef'}=$uriString[$lengthUriString-1];
   }
   $dataflowRef=$hashWf{$nodeName}{$uriName}{'dataflowRef'};
   #print("DataflowRef fuera: $dataflowRef\n");

#    $found=0;
#    @nodes_name=($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']'));
# #   @nodes_name=($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:processors/ns:processor'));
#    while(($node = shift(@nodes_name)) && ($found==0)){
#        $uriTemp = get_uri_currentNode_t2flow($node,$wfId);
#        print("uriTemp: $uriTemp\n");
#        print("node: ".$node->textContent."\n");
#        if($uriTemp eq $uriName){
# 	   $found=1;
# 	   @datalinks = ((($node->getChildrenByTagName("datalinks"))[0])->getChildrenByTagName("datalink"));
   @datalinks = ($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:datalinks/ns:datalink[ns:sink/ns:port=\''.$dataName.'\']')); 
   foreach $datalink (@datalinks){
# 	       if( (((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("port"))[0])->textContent eq $dataName ){ # Links associated to nameA as source.
       @linkFromServiceNotInput_array=((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("processor"));
       $linkFromServiceNotInput=(scalar @linkFromServiceNotInput_array);
       if($linkFromServiceNotInput == 1){ 
	   # If it isn't a service, it's a direct link to Input, not to service. Not interest on it.
	   $nameA=((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("processor"))[0]->textContent;
	   #URI_A:
	   if(($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:processors/ns:processor[ns:name="'.$nameA.'"]'))->size > 0){
	       $nodeA=(($dataStructureRoot->findnodes('//ns:workflow/ns:dataflow[@id=\''.$dataflowRef.'\']/ns:processors/ns:processor[ns:name="'.$nameA.'"]'))[0]);
	       $uriA = get_uri_currentNode_t2flow($nodeA,$wfId);
# 		       $foundA=0;
# 		       @nodes_nameA=$node->getChildrenByTagName("processor");
# 		       while(($nodeA = shift(@nodes_nameA)) && ($foundA==0)){
# 			   if( (($nodeA->getChildrenByTagName("name"))[0])->textContent eq $nameA){
# 			       $foundA=1;
# 			       $uriA = get_uri_currentNode_t2flow($nodeA,$wfId);
# 			   } # end-if nodeB found
# 		       } # end-while looking for URI A

	       if(defined($hashWf{$nameA}{$uriA})){		  
		   $dataA=((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("port"))[0]->textContent;
		   $pA=$nameA.":".$dataA;
		   $idA=$pA.":URI:".$uriA;
		   if(($hashWf{$nameA}{$uriA}{'type'}) eq 'dataflow.DataflowActivity'){ # Base case
		       simpleServiceSource_t2flow($wfId,$nameA,$dataA,$uriA,$idB,$dataStructureRoot,$dataGenBy,\%hashWf);
		   }else{ # Base case
		       #pA with right value: to manage pB
		       #$pB=$processB;
		       $nameB=(split("\:",$idB))[0];
		       $uriB=(split("\:URI\:",$idB))[1];
		       if(($hashWf{$nameB}{$uriB}{'type'}) ne 'dataflow.DataflowActivity'){
			   if(!defined $dataGenBy->{$idA}){
			       $dataGenBy->{$idA}++;
			       #print("New data (source)!!!: $idA\n");
			   } # end-if not repeated GeneratedBy
			   #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
			   $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
			   if($matched == 0){
			       push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
			       #print("Push uses: $idA->$idB\n");
			   } # end-if not repeated uses
		       }else{
			   $dataB=(split("\:",$idB))[1];
			   simpleServiceSink_t2flow($wfId,$nameB,$dataB,$uriB,$idA,$dataStructureRoot,$dataGenBy,\%hashWf);
		       } # end-if B==nestedWf
		   } # end-if A==nestedWf
	       } # end-if A is service
	   } # if processor with nameA exists
       } # end-if A is not linkFromServiceNotInput
   } # end-for each datalink
#	       } # end-if A is not linkFromServiceNotInput
# 	   } # end-if datalink with source is equal to nameA
#        } # end-if uriTemp==uriName
#    } # end-while $node with the same name
   return;
} # end-sub-simpleServiceSource_t2flow


################################################################
# load_datalinks_to_workflow
################################################################
sub load_datalinks_to_workflow{
# Use: 	load_datalinks_to_workflow($wfId,$wfFile,@listURIs);
  my $wfId = shift;
  my $file = shift;
  my $dataGenBy = shift;
  my %hashWf = %{(shift)};

  # print("load_datalinks_to_wf: dataGenBy: $dataGenBy\n");
  # print("load_datalinks_to_wf: hashWf: %hashWf\n");

  my (@line1, @line2, $ext, $servName);
  my ($parser, $doc, $root);

  @line1=split("wf_myExperiment_",$file);
  @line2=split("\\.",$line1[1]);
  $ext=$line2[1];

  my ($queryProcessorName, $nodeA, $parent, $datalink, $linkToServiceNotOutput, @linkToServiceNotOutput_array, @datalinks);
  my ($pA,$nameA,$dataA,$uriA,$idA,$pB,$nameB,$dataB,$uriB,$idB);
  my ($found, $foundA, $foundB, @nodes_nameA, @nodes_nameB, $uriTemp, $nodeB, $matched);


  $parser = XML::LibXML->new();
  $doc = $parser->parse_file($file); # Return XML::LibXML::Document
     
  # SCUFL format
  if($ext eq "xml"){ # SCUFL format (Taverna 1)  
      $root = $doc->getDocumentElement; # Return XML::LibXML::Node
      foreach $nameA (keys %hashWf){
	  foreach $uriA (keys %{$hashWf{$nameA}}){
	      #print(">>> $nameA:$uriA\n");
	      $queryProcessorName='/descendant::s:processor[@name=\''.$nameA.'\']';
	      # $nodeA = ($root->findnodes($queryProcessorName))[0]; 
	      $foundA=0;
	      @nodes_nameA=$root->findnodes($queryProcessorName);
	      while(($nodeA = shift(@nodes_nameA)) && ($foundA==0)){
		  $uriTemp = get_uri_currentNode_scufl($nodeA,$wfId);
		  if($uriTemp eq $uriA){
		      $foundA=1;
		      $parent = $nodeA->parentNode;
		      foreach $datalink ($parent->getChildrenByTagName("s:link")){
			  if($datalink->getAttribute("source") =~ "^$nameA:" ){ # Links associated to nameA as source.
			      $pA=$datalink->getAttribute("source");
			      $pB=$datalink->getAttribute("sink");
			      $idA=$pA.":URI:".$uriA; # idA=nameA:dataA:URI:uriA
			      $linkToServiceNotOutput=($pB =~ ":");	  
			      $nameB=(split("\:",$pB))[0];
			      if($linkToServiceNotOutput == 1){
				  # If it isn't a service, it's a direct link to Output, not to service. Not interest on it.
				  # URI_B:
				  # How can I get the URI in the right context? Searching inside parent, and only in one level (childNodes)!
				  $foundB=0;
				  @nodes_nameB=$parent->getChildrenByTagName("s:processor");
				  while(($nodeB = shift(@nodes_nameB)) && ($foundB==0)){
				      if(($nodeB->getAttribute("name")) eq $nameB){
					  $foundB=1;
					  $uriB = get_uri_currentNode_scufl($nodeB,$wfId);
				      } # end-if nodeB found
				  } # end-while looking for URI B

				  $idB=$pB.":URI:".$uriB;
				  if (defined($hashWf{$nameB}{$uriB})){
				      if($hashWf{$nameA}{$uriA}{'type'} ne 'workflow'){  ### In T2flow: dataflow.DataflowActivity
					  if($hashWf{$nameB}{$uriB}{'type'} ne 'workflow'){  ### In T2flow: dataflow.DataflowActivity

					      if(!defined $dataGenBy->{$idA}){
						  $dataGenBy->{$idA}++;
						  #print("New data (global)!!!: $idA\n");
					      } # end-if not repeated GeneratedBy
					      #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
					      $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
					      if($matched == 0){
						  push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
						  #print("Push uses: $idA->$idB\n");
					      } # end-if not repeated uses
					      #else{
					      #	  print("Repeated uses: $pA\n");
					      #}
					  }else{
					      $dataB=(split("\:",$pB))[1];
					      simpleServiceSink($wfId,$nameB,$dataB,$uriB,$idA,$root,$dataGenBy,\%hashWf);
					  } # end-if B==nestedWf             
				      }else{
					  $dataA=(split("\:",$pA))[1];
					  simpleServiceSource($wfId,$nameA,$dataA,$uriA,$idB,$root,$dataGenBy,\%hashWf);
				      } # end-if A==nestedWf 
				  } # end-if B is defined
			      } # end-if B is service (linkToServiceNotOutput == 1)
			  } # end-if datalink with source START with ^nameA
		      } # end-foreach $datalink
		  } # end-if uriA==uriTemp
	      } # end-while $nodeA with the same name
	  } # end-foreach uri with the same servName
     } # end-foreach processor or services with annotations
  }elsif($ext eq "t2flow"){
      # Does it also work with nested workflow????? taking into account datalinks among nested workflows, due to nested workflows are considered as processor in the 'top' (main) workflow.
      # IMP: The same t2flow could have several dataflow tags (from nested workflows)!!! This code counts services from all dataflows
      $root = XML::LibXML::XPathContext->new($doc);
      $root->registerNs('ns','http://taverna.sf.net/2008/xml/t2flow');

      foreach $nameA (keys %hashWf){
	  foreach $uriA (keys %{$hashWf{$nameA}}){
	      #print(">>> $nameA:$uriA\n");
	      $foundA=0;
	      @nodes_nameA=($root->findnodes('//ns:workflow/ns:dataflow/ns:processors/ns:processor[ns:name=\''.$nameA.'\']')); 
	      while(($nodeA = shift(@nodes_nameA)) && ($foundA==0)){
		  $uriTemp = get_uri_currentNode_t2flow($nodeA,$wfId);
		  if($uriTemp eq $uriA){
		      #print("nameA: $nameA\n");
		      $foundA=1;
		      $parent = ($nodeA->parentNode)->parentNode;
		      #@datalinks= (root->findnodes('//ns:workflow/ns:dataflow[ns:processors/ns:processor/ns:name=\''.$nameA.'\']/ns:datalinks/ns:datalink[ns:source/ns:processor=\''.$nameA.'\']')); 
		      @datalinks = ((($parent->getChildrenByTagName("datalinks"))[0])->getChildrenByTagName("datalink"));
		      foreach $datalink (@datalinks){
			  if( ((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("processor"))->size() > 0 ){
			      #print("datalink: ".$datalink->textContent."\n");
			      if( (((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("processor"))[0])->textContent eq $nameA ){ # Links associated to nameA as source.
				  $dataA=(((($datalink->getChildrenByTagName("source"))[0])->getChildrenByTagName("port"))[0])->textContent;
				  $pA=$nameA.":".$dataA;
				  $idA=$pA.":URI:".$uriA;
				  @linkToServiceNotOutput_array=((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("processor"));
				  $linkToServiceNotOutput=(scalar @linkToServiceNotOutput_array);
				  if($linkToServiceNotOutput == 1){
				      # If it isn't a service, it's a direct link to Output, not to service. Not interest on it.
				      $nameB=(((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("processor"))[0])->textContent;
				      # URI_B:
				      # How can I get the URI in the right context? Searching inside parent, and only in one level (childNodes)!
				      $foundB=0;
				      @nodes_nameB=($nodeA->parentNode)->getChildrenByTagName("processor");
				      while(($nodeB = shift(@nodes_nameB)) && ($foundB==0)){
					  if( (($nodeB->getChildrenByTagName("name"))[0])->textContent eq $nameB){
					      #print("nameB: $nameB\n");
					      $foundB=1;
					      $uriB = get_uri_currentNode_t2flow($nodeB,$wfId);
					  } # end-if nodeB found
				      } # end-while looking for URI B
				      
				      if(defined($hashWf{$nameB}{$uriB})){		  
					  $dataB=(((($datalink->getChildrenByTagName("sink"))[0])->getChildrenByTagName("port"))[0])->textContent;  
					  $pB=$nameB.":".$dataB;
					  $idB=$pB.":URI:".$uriB;
					  if($hashWf{$nameA}{$uriA}{'type'} ne 'dataflow.DataflowActivity'){
					      if($hashWf{$nameB}{$uriB}{'type'} ne 'dataflow.DataflowActivity'){
						  if(!defined $dataGenBy->{$idA}){
						      $dataGenBy->{$idA}++;
						      #print("New data (global)!!!: $idA\n");
						  } # end-if not repeated GeneratedBy
						  #if(grep(/$idA/,@{$hashWf{$nameB}{$uriB}{'uses'}}) == 0){ # It doesn't work
						  $matched = grep $_ eq $idA, @{$hashWf{$nameB}{$uriB}{'uses'}};
						  if($matched == 0){
						      push(@{$hashWf{$nameB}{$uriB}{'uses'}},$idA);
						      #print("\tPush uses: $idA->$idB\n");
						  } # end-if not repeated uses
						  #else{
						  #	  print("Repeated uses: $pA\n");
						  #}
					      }else{	      
						  simpleServiceSink_t2flow($wfId,$nameB,$dataB,$uriB,$idA,$root,$dataGenBy,\%hashWf);
					      } # end-if B==nestedWf             
					  }else{		  
					      simpleServiceSource_t2flow($wfId,$nameA,$dataA,$uriA,$idB,$root,$dataGenBy,\%hashWf);
					  } # end-if A==nestedWf 
				      } # end-if B is service
				  } # end-if link to service not output
			      } # end-if datalink with source is equal to nameA
			  } # end-if datalink with source+processor
		      } # end-foreach $datalink
		  } # end-if uriA==uriTemp
	      } # end-while $nodeA with the same name
	  } # end-foreach uri with the same servName
      } # end-foreach processor or services with annotations
  } # end-else T2flow format

  return;
} # end-sub load_datalinks_to_workflow



###########################################################################
#
############################## MAIN PROGRAM ###############################
#
###########################################################################

# Building output directory
my $dirWf=$ARGV[0];
my $dirAnnot=$ARGV[1];
my $dirRedundAnnot=$ARGV[2];
my $templateICvaluefile=$ARGV[3];
my $wfTest=$ARGV[4];

my $firstChar=substr($dirAnnot,0,1);
if($firstChar ne "/"){
    die ">>ERROR in argument: The second argument must be an ABSOLUTE path (not a relative one)";
}
my $l=length($dirAnnot);
my $lastChar=substr($dirAnnot,$l-1,$l);
if($lastChar ne '/'){
    $dirAnnot=$dirAnnot."/";
} #end-if

$firstChar=substr($dirRedundAnnot,0,1);
if($firstChar ne "/"){
    die ">>ERROR in argument: The third argument must be an ABSOLUTE path (not a relative one)";
}
$l=length($dirRedundAnnot);
$lastChar=substr($dirRedundAnnot,$l-1,$l);
if($lastChar ne '/'){
    $dirRedundAnnot=$dirRedundAnnot."/";
} #end-if

$l=length($dirWf);
$lastChar=substr($dirWf,$l-1,$l);
if($lastChar ne '/'){
    $dirWf=$dirWf."/";
} #end-if

# To load IC values per ontology file in a hash sorted by term URI
my %ICvalues=();
my ($fileInICvalue, @line);
if((defined $ARGV[3]) && (defined $ARGV[4])){
    for my $ont (qw/BAO BRO EDAM EFO IAO MESH MS NIFSTD NCIT OBI OBIWS SIO SWO/){	
	($fileInICvalue = $templateICvaluefile) =~ s/XXXontXXX/${ont}/;
	open(IN,"<$fileInICvalue") or die "Couldn't open: $fileInICvalue";
	while(<IN>){
	    if($_ =~ "^http"){
		chomp;
		@line=split("\\t",$_);
		$ICvalues{$ont}{$line[0]}=$line[1];
	    } # end-if URI line
	} # end-while IN
	close(IN);
    } # end-for ontology
} # end-if argv3 and argv4 exists


my $dirGraphs=$dirAnnot."Graphs/";
mkdir $dirGraphs;

my $prefix="wf_myExperiment_*";
my @files;

# To generate tab file with wfId, nameServ, type, url-service, url-annotation
my $fileAnnotURIs=$dirAnnot."wf_service_type_URI_annotation.txt";
@files=<$dirAnnot$prefix>; #my @files=<../Data/WF_myExperiment/NotRedundantAnnot/wf_myExperiment_*>;
generate_serv_annot_tab_file($fileAnnotURIs,@files);

# To load all URI links of services and their corresponding annotations from the common file
my @listURIs=();
@listURIs=load_annotation_uris($fileAnnotURIs,@listURIs);
#print_arrayHashAnnot(@listURIs);

my %listWfIds=(); # List of wfIds
my %listServURIs=(); # List of services opaque URIs

print("#wfID\tno.nodes\tno.links");       
my (@line1, @line2, $wfId, $fileOut, $fileDatalinks, $fileGif, $fileSvg, $fileIn);
my %dataGeneratedBy=();
@files=<$dirWf$prefix>; #my @files=<../Data/WF_myExperiment/wf_myExperiment_*>;
foreach my $wfFile (@files){
    if((index($wfFile,"_withoutShims")) > -1){
	# New workflow
	@line1=split("wf_myExperiment_",$wfFile);
	@line2=split("\_withoutShims",$line1[1]);
	$wfId=$line2[0];

	%dataGeneratedBy=delete_hash(\%dataGeneratedBy);

	if($wfId != 379){ # wf379: rare workflow.
#	    if($wfId == $wfTest){ # TEST WITH JUST ONE WORKFLOW!!!!
	    if(defined $listURIs[$wfId]){
		print("\n*****WORKFLOW $wfId:");
		$listWfIds{$wfId}++;
		load_datalinks_to_workflow($wfId,$wfFile,\%dataGeneratedBy,\%{$listURIs[$wfId]});
	        #print_hashOneWfAndData(\%dataGeneratedBy,\%{$listURIs[$wfId]});

	    # To write OPMW file, looping through hashes
            # IMPORTANT: To generate 'uses' and 'isGeneratedBy' (push(@{$list[$wfId]{$servName}{'isGeneratedBy'}},$link)) iterating by linkAtoB hash. If the name of the parameter/port (after ':') is the same, the random data generated must be the same, else a different one. To generate data identifier in a randow way. With the structure: http://www.wilkinsonlab.info/myExperiment_Annotations/exampleData/wf0000/dataXX
# To include also nested-wf annotations, although they are disconnected (after, for building the graphs, I should remove them).
		$fileOut=$dirAnnot."wf_myExperiment_".$wfId."_annotations_datalinks.ttl";
		print_annotation_per_workflow_ttl($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});
		$fileOut=$dirAnnot."wf_myExperiment_".$wfId."_annotations_datalinks.rdf";
		print_annotation_per_workflow_rdf($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});
		$fileOut=$dirAnnot."wf_myExperiment_".$wfId."_annotations_datalinks.gv";
		$fileDatalinks=$dirAnnot."wf_myExperiment_".$wfId."_datalinks.txt";
		print_gvFile($wfId,$fileOut,$fileDatalinks,\%{$listURIs[$wfId]});
		# To generate graphical file (now in .gif, although it could be other format)
		$fileGif=$dirGraphs."wf_myExperiment_".$wfId."_annotations_datalinks.gif";
		system("dot -Tgif $fileOut -o $fileGif");
		$fileSvg=$dirGraphs."wf_myExperiment_".$wfId."_annotations_datalinks.svg";
		system("dot -Tsvg $fileOut -o $fileSvg");		

		# To generate additional OPMW files, with justTypeServ and justURIserv
		$fileOut=$dirAnnot."wf_myExperiment_".$wfId."_annotations_typeIsCategory.rdf";
		print_annotation_per_workflow_rdf_justTypeServ($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});
		$fileOut=$dirAnnot."wf_myExperiment_".$wfId."_annotations_typeIsURIserv.rdf";
		print_annotation_per_workflow_rdf_justURIserv($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});


                # PENDING: After it is working with the easy parameter configuration, to define empty function per each new output, being the hash a parameter
		if (-d $dirRedundAnnot){
		    # To create new output folders
		    my $dirOutOnt;
		    $dirOutOnt=$dirRedundAnnot."AnnotPerOnt";
		    mkdir $dirOutOnt;
		    $dirOutOnt=$dirRedundAnnot."AnnotPerOntJustOneTerm";
		    mkdir $dirOutOnt;		    
		    for my $ont (qw/BAO BRO EDAM EFO IAO MESH MS NIFSTD NCIT OBI OBIWS SIO SWO/){
			# A.- To generate OPMW files split by ontology, with all the annotations
			$dirOutOnt=$dirRedundAnnot."AnnotPerOnt/${ont}";
			mkdir $dirOutOnt;
			$fileIn=$dirRedundAnnot."wf_myExperiment_".$wfId."_edamAnnotations.txt";
			change_annotation_uris($wfId,$ont,$fileIn,\%{$listURIs[$wfId]});
			$fileOut=$dirOutOnt."/wf_myExperiment_".$wfId."_annotations_datalinks_${ont}.rdf";
			print_annotation_per_workflow_rdf($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});

			# B.- To generate OPMW files split by ontology, with just one term (i.e.annotation) per ontology
			$dirOutOnt=$dirRedundAnnot."AnnotPerOntJustOneTerm/${ont}";
			mkdir $dirOutOnt;
			$fileIn=$dirRedundAnnot."wf_myExperiment_".$wfId."_edamAnnotations.txt";
			getjustOne_annotation_uri($wfId,$ont,\%{$ICvalues{$ont}},\%{$listURIs[$wfId]});
			$fileOut=$dirOutOnt."/wf_myExperiment_".$wfId."_annotations_datalinks_oneTerm_${ont}.rdf";
			print_annotation_per_workflow_rdf($wfId,$fileOut,\%dataGeneratedBy,\%{$listURIs[$wfId]});
		    } # end-for ontology
		} # end-if -d $dirRedundAnnot
	    } # end-if wf with annotations
#	    } # end-if wfId equal to wfTest
	} # enf-if wfId different from specific values	
    } # end-if original file 
 } # end-foreach workflow



# SemSim AMONG SERVICES:
# To generate files with all-against-all services SemSim per ontology
# In whatever workflow, I don't require that the services would be in the same workflow, since every one has their univocal URI, and it is defined with their questions.
if (-d $dirRedundAnnot){ # If NewAnnot available 
    for my $ont (qw/BAO BRO EDAM EFO IAO MESH MS NIFSTD NCIT OBI OBIWS SIO SWO/){
	%listServURIs=delete_hash(\%listServURIs);
	# 1.- To load again the NewAnnot (including redundant) in the hash structure.
	# The %dataGeneratedBy content is lost, since it is computed wf by wf, and re-written. It doesn't matter, since the links are not neccessary, because this is a all-against-all computation.
	foreach my $wfId (keys %listWfIds){
	    if($wfId != 379){ # wf379: rare workflow.
		$fileIn=$dirRedundAnnot."wf_myExperiment_".$wfId."_edamAnnotations.txt";
		change_annotation_uris($wfId,$ont,$fileIn,\%{$listURIs[$wfId]});
		# To add, to a list, the URIs of all services in this workflow
		%listServURIs=add_servURIs_toList(\%listServURIs,\%{$listURIs[$wfId]});
	    } # enf-if wfId different from specific values	
	} # end-foreach workflow

	# 2.- To iterate in list of services, generating all-against-all possible pairs
	$fileOut=$DIRsml."/SemSimNodes/data/${ont}_queries.csv";
	open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
	foreach my $serv1 (sort keys %listServURIs){
	    foreach my $serv2 (sort keys %listServURIs){
		print(OUT "$serv1\t$serv2\n");
	    }  # end-foreach serv2
	} # end-foreach serv1
	close(OUT);

	# 3.- To iteratate in list of services, to generate: service + its annotations
	$fileOut=$DIRsml."/SemSimNodes/data/instances_annot_${ont}.tsv";
	open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
	my $stringAnnot="";
	foreach my $wfId (sort keys %listWfIds){
	    if($wfId != 379){ # wf379: rare workflow.
		foreach my $servName (keys %{$listURIs[$wfId]}){
		    foreach my $servUri (keys %{$listURIs[$wfId]{$servName}}){
			if((scalar @{$listURIs[$wfId]{$servName}{$servUri}{'annot'}}) > 0){
			    # The SMLtoolkit just takes into account instances with at least one URI (i.e. one annotation)
			    $stringAnnot=join(';',@{$listURIs[$wfId]{$servName}{$servUri}{'annot'}});
			    print(OUT "$listURIs[$wfId]{$servName}{$servUri}{'opaqueURI'}\t$stringAnnot\n");
			} # end-if there are annotations
		    } # end-foreach service
		} # end-foreach workflow
	    } # enf-if wfId different from specific values	
	} # end-foreach workflow
	close(OUT);

	# To retrieve semSimilarities, calling to SMLtoolkit
	my $pwd = cwd();
	chdir($DIRsml);
	system("java -DentityExpansionLimit=10000000 -jar sml-toolkit-0.8.2.jar -t sm -xmlconf SemSimNodes/conf_semSimNodes_${ont}.xml > SemSimNodes/results/outputSML_".${ont}.".txt");
	unlike($DIRsml."/SemSimNodes/data/${ont}_queries.csv");
	chdir($pwd);

    } # end-for ontologies
} # end-if exists dirRedundAnnot


