## Fragmentation and computing subgraphs distance matrix per ontology
# It requires the SML tookit (http://www.semantic-measures-library.org/sml/) 

use strict;
use warnings;
use Cwd;
use Graph;
use Graph::Subgraph;
use List::PowerSet qw(powerset powerset_lazy);
use File::Copy;
use POSIX;

################################################################
# generate_serv_annot_tab_file
################################################################
sub generate_serv_annot_tab_file_perOntology($$\@) {
# To generate tab file with wfId, nameServ, type, url-service, url-annotation
# Call: generate_serv_annot_tab_file_perOntology(ClusteringSubgraphs/wf_service_type_URI_annotation_EDAM.txt,EDAM,@{<"../Data/WF_myExperiment_2014.03.15/NewAnnot/wf_myExperiment_*">});

# This method is practically the same as generate_serv_annot_tab_file() from loop_generateAnnotationsInOPMW.pl. So, the input files need to be cleaned from unknown services, as they are received in the original methods. It means, better 'NewAnnot' than root of annotations.

  # Parameters
  my $fileOut = shift;
  my $ontology = shift;
  my @files = @{(shift)};
  
  my ($wfId, @line1, @line2);
  my (@line, $fileIn, $nameServ, $typeServ, $uriServ, $contAnnot, $contData, $uriAnnot, $contBiomart, $contRshell, $okToPrint);

  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "#WfId\tService name\tService type\tURI\tAnnotation URI\n");
  foreach my $wfFile (@files){
      if((index($wfFile,"_edamAnnotations.txt")) > -1){
	  @line1=split("wf_myExperiment_",$wfFile);
	  @line2=split("\\_edamAnnotations.txt",$line1[1]);
	  $wfId=$line2[0];

	  open(IN,"<$wfFile") or die "Couldn't open: $wfFile";

	  $uriServ="";
	  $nameServ="";
	  $typeServ="";
	  $contData=0;
	  $contAnnot=0;
	  $contBiomart=1;
	  $contRshell=1;
	  $okToPrint=1; # If service isn't a Biomoby Object.
	  while(<IN>){
	      if($_ =~ "^---------------"){
		  if($okToPrint){
		      if($contData > 0){
			  # Print remainder lines last service
			  if($contAnnot == 0){
			      # Write line with the uri of the Serv, when it has not annotations. 
			      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t---\n");
			  } # end-if $contAnnot<=0
		      } # end-if $contData > 0
		  } # end-if okToPrint
		  # To initialize new service
		  $uriServ="";
		  $nameServ="";
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
		  
	      }elsif($_ =~ "^\t$ontology"){
#	      }elsif(($_ =~ "^\tBAO") || ($_ =~ "^\tOBIWS") || ($_ =~ "^\tBRO") || ($_ =~ "^\tEDAM") || ($_ =~ "^\tIAO") || ($_ =~ "^\tMS") || ($_ =~ "^\tMESH") || ($_ =~ "^\tOBI") || ($_ =~ "^\tSWO") || ($_ =~ "^\tEFO") || ($_ =~ "^\tNCIT") || ($_ =~ "^\tNIFSTD") || ($_ =~ "^\tSIO")){

		  chomp;
		  @line=split("\\t",$_);
		  $uriAnnot=$line[4];
		  
		  if($okToPrint){
		      $contAnnot=$contAnnot+1;
		      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t$uriAnnot\n");
		  } # end-if okToPrint
	      } # end-if type of line in annotation file
	  } # end-while
	  # Print remainder lines last service
	  if($okToPrint){
	      if($nameServ ne ""){ # It really exists some services. To avoid write lines for empty workflows.
		  if($contAnnot == 0){ # Write line with the uri of the Serv, when it has not annotations. 
		      print(OUT "$wfId\t$nameServ\t$typeServ\t$uriServ\t---\n");
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
  my $file = shift;
  my @list = @{(shift)};
  my (@line, $wfId, $servName, $servType, $servUri, $annotUri, $matched);
  
  
  open(IN,"<$file") or die "Couldn't open: $file";
  while(<IN>){
      if(!($_ =~ "^#")){
	  chomp;
	  @line=split("\\t",$_);
	  
	  $wfId=$line[0];
	  $servName=$line[1];
	  $servType=$line[2];
	  $servUri=$line[3];
	  $annotUri=$line[4];
	  $list[$wfId]{$servName}{$servUri}{'name'}=$servName;
	  $list[$wfId]{$servName}{$servUri}{'type'}=$servType;
	  $list[$wfId]{$servName}{$servUri}{'URI'}=$servUri; # instead of:  $list[$wfId]{$servName}{'URI'}=$servUri; # I can't define a hash with wfId as ref!!
	  if(defined $annotUri){
	      if($annotUri ne "---"){
		  $matched = grep $_ eq $annotUri, @{$list[$wfId]{$servName}{$servUri}{'annot'}};
		  if($matched == 0){
		      push(@{$list[$wfId]{$servName}{$servUri}{'annot'}},$annotUri);
		  } # end-if annot not included in array
	      } # end-if annot <> ---
	  } # end-if exists annot
      } # skip header
  } # end-while
  close(IN);

  return(@list);
} # end-sub load_annotation_uris


################################################################
# print_arrayHashAnnot
################################################################
sub print_arrayHashAnnot(\@) {
  # Parameters
  my @list = @{(shift)};

  my $lastIndex = $#list;
  
  my $wfId=1;
  while($wfId <= $lastIndex){
      print(">>>Wf$wfId:\n");
      foreach my $servName (keys %{$list[$wfId]}){
	  foreach my $servUri (keys %{$list[$wfId]{$servName}}){
	      print("\t$servName\t$list[$wfId]{$servName}{$servUri}{'type'}\t$servUri\n");
	      foreach my $termUri (@{$list[$wfId]{$servName}{$servUri}{'annot'}}){
		  print("\t\t$termUri\n");
	      } # end-for annotation
	  } # end-foreach servUri
      } # end-foreach servName
      $wfId=$wfId+1;
      print("\n");
  } # end-while wfId
} # end-sub print_arrayHashAnnot


################################################################
# print_hashOneWfAndData
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
} # end-sub print_hashOneWfAndData


################################################################
# print_gvFile_subgraph
################################################################
sub print_gvFile_subgraph{
  # Use: print_gvFile($wfId,$fileOut,$directedGraph);
    
  # Parameters
  my $wfId = shift;
  my $fileOut = shift;  
  my $graph = shift;

  my ($sourceProcessName, $type, $colorServ, $printName, $printNameSink, $printNameSource, $sourceUriName, $servName);
  my (@verticesList, @edgesList);
  my $countServices=0;
  my $countLinks=0;
 
  # To write file header
  open(OUT,">$fileOut") or die "Couldn't open: $fileOut";
  print(OUT "digraph subW".$wfId."{\n");

  # To write services names (although it isn't need if all of them have links.).
  print(OUT "\t/*nodes names. */\n");
  print(OUT "\tnode [shape=box,color=black];\n"); 

  @verticesList = $graph->vertices;
  foreach my $vert (@verticesList){
      $countServices=$countServices+1;
      # Colors from Taverna [http://dev.mygrid.org.uk/wiki/display/tav250/Workflow+Diagram] vs Graphviz [http://www.graphviz.org/doc/info/colors.html]
      $type=$vert->{'type'};
      $servName=$vert->{'name'};
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
      $printName="\"".$countServices.":".$servName."\"";
#	  if(($servName =~ "-") || ($servName =~ "\\(") || ($servName =~ "\\.")){
#  	      $printName="\"".$servName."\"";
# 	  }
      $vert->{'gvID'}=$printName;
      print(OUT "\t$printName [style=filled,fillcolor=$colorServ,URL=\"$vert->{'URI'}\"];\n");
  } # end-foreach vertice
  print(OUT "\n");

  # Third: To write each link
  @edgesList=$graph->edges;
  foreach my $edge (@edgesList){
      print(OUT "\t@{$edge}[0]->{'gvID'} -> @{$edge}[1]->{'gvID'};\n");
  } # end-foreach edge

  print(OUT "}\n");
  close(OUT);
} # end sub print_gvFile


################################################################
# compute_semSim_2subWfs($@@)
# This subroutine takes two array of annotations, to compute semSim values. That is arrays of URIs.
################################################################
sub compute_semSim_2subWfs {
# Call: compute_semSim_2subWfs (\@subWf1Annot,\@subWf2Annot)
  # Parameters
  my $icMetric = shift; #'ICI_ZHOU_2008' or With all ontologies: ICI_SANCHEZ_2011
  my $pairwiseMetric = shift; #'SIM_PAIRWISE_DAG_NODE_SCHLICKER_2006' or 'SIM_PAIRWISE_DAG_NODE_JIANG_CONRATH_1997'
  my $groupwiseMetric = shift; #'SIM_GROUPWISE_BMA'
  my $ont = shift;
  my ($setAnnot1, $setAnnot2) = @_;

  my $semSim=0.0; # Output value

#   print("ic Metric: $icMetric\n");
#   print("pair Metric: $pairwiseMetric\n");
#   print("group Metric: $groupwiseMetric\n");
#   print("Symmetric aggregator: $symmetricAggre\n");

  # After having an initial draft:
  # A) TO-DO!!!!!!!!!!!!!!!! IMP: SML toolkit: Except to EDAM, MS and OBIWS, the rest of SML conf files are ready to use URIs in the queries file. Try to change these others, to be uniform, if it's possible.


  # With calls to SML toolkit!!!
  # Should I write an URI of each list per column or how to do that to compute a groupwise measure??
  # I'm not sure about if I should write all the possible pairs of annotations of the different sets and after to compute by myself the BestMatchAverage (probably that), or if SML toolkit computes groupwiseMetric be itself.
#   ########### TO-FILLLLLLLLLLLLLL: WAITING FOR AN ANSWER!!!!!!!!!!
#   foreach my $item1 (@{$setAnnot1}){
#       foreach my $item2 (@{$setAnnot2}){
# 	  # To write list of $items (URIs) in a file. 
# 	  # IF SML toolkit computes groupwise, I should write a file with: 
# 	  # subWf_1 \t ontTerm1;ontTerm2;...\n
# 	  # subWf_1 \t ontTerm1;ontTerm2;...\n
# 	  # ...
# 	  # + other file with all the possible combinations of Subworkflows:
# 	  # subWf_1 \t subWf_2
# 	  # subWf_2 \t subWf_1
# 	  # subWf_1 \t subWf_3
# 	  # ...
# 
# 	  print("[$item1, $item2]\n");
#       } # end-for setAnnot2
#   } # end-for setAnnot1

  my $DIRsml="SML_toolkit";
  my $annotString1 = join(';',@{$setAnnot1});
  my $annotString2 = join(';',@{$setAnnot2});
  open(OUT,">SML_toolkit/SemSimSubWfs/data/".$ont."_queries.csv") or die "Couldn't open: queries file!";
  print(OUT "$annotString1\t$annotString2\n");
  close(OUT);

  #To retrieve annotations 
  #To get queries file
  #To call SML
  my $pwd = cwd();
  chdir($DIRsml);
  system("java -DentityExpansionLimit=10000000 -jar sml-toolkit-0.8.2.jar -t sm -xmlconf SemSimSubWfs/conf_semSimSubWfs_${ont}.xml >> SemSimSubWfs/results/outputSML_".$ont.".txt");
  chdir($pwd);

  open(RESULTS, "<$DIRsml/SemSimSubWfs/results/".$ont."_results.csv");
  my $count=1;
  while(<RESULTS>){
      if($count == 2){
	  chomp;
	  $semSim=(split("\\t",$_))[2];
	  print("semSim: $semSim\n");
      }
      $count=$count+1;
  }
  close(RESULTS);

  return($semSim);
} # end-sub compute_semSim_2subWfs





#################################################################################################
#################################################################################################
#################################################################################################


my ($l, $lastChar, $prefix, @files, $linksWfFile, @line, @source, @sink, @subWfIDarray, $indArray, $wholeGraph, $sourceVar, $sinkVar, $fileOut, $fileSvg, @annotSubGraph, @annotSubGraphCurrent, $subWfName, $subWfID, %subWfIDhash, $matched, $numElem, $decMax, @binArray, $maxElem, @subset, $fragmentGraph, @allCombinations, $minReal, $maxReal);


my $dirInAnnot=$ARGV[0];
my $dirInLinks=$ARGV[1];
my $ontology=$ARGV[2];
my $minSubgraphNodes=$ARGV[3]; # Beginning: 2, after it could be 1, to find group of nodes similar to an isolated node. It makes specially sense when the isolated node is a nested workflow.
my $maxSubgraphNodes=$ARGV[4]; # Beginning: 3, after 4, etc.

my $icMetric='ICI_ZHOU_2008'; #With all ontologies: ICI_SANCHEZ_2011
my $pairwiseMetric='SIM_PAIRWISE_DAG_NODE_SCHLICKER_2006'; #or'SIM_PAIRWISE_DAG_NODE_JIANG_CONRATH_1997'
my $groupwiseMetric='SIM_GROUPWISE_BMA';
# It isn't necessary, since SMLtoolkit, with BMA, assumes 'Avg' symmetriztion.
# my $symmetrizationOperator="Avg"; # Values={Min, Max, Avg}. To combine sim(w1,w2) with sim(w2,w1). distance=1-($symmetrizationOperator(SemSim(w1,w2),SemSim(w2,w1))



$l=length($dirInAnnot);
$lastChar=substr($dirInAnnot,$l-1,$l);
if($lastChar ne '/'){
    $dirInAnnot=$dirInAnnot."/";
} #end-if
$l=length($dirInLinks);
$lastChar=substr($dirInLinks,$l-1,$l);
if($lastChar ne '/'){
    $dirInLinks=$dirInLinks."/";
} #end-if


my $dirOut=$dirInAnnot."ClusteringSubgraphs${ontology}/";
mkdir($dirOut);

# 1.- To store annotations of selected ontology per each node
my $fileAnnotURIs=$dirOut."wf_service_type_URI_annotation_$ontology.txt";
$prefix="wf_myExperiment_*";
@files=<$dirInAnnot$prefix>; #my @files=<../Data/WF_myExperiment_2014.06.03/wf_myExperiment_*>;
generate_serv_annot_tab_file_perOntology($fileAnnotURIs,$ontology,@files);

my @listURIs=();
@listURIs=load_annotation_uris($fileAnnotURIs,@listURIs);
unlink($fileAnnotURIs);


my $subWfCount=0; # General count, for subwf in all workflows.
@subWfIDarray=();
$indArray=0;


my $lastIndex = $#listURIs;
my $wfId=1;
while($wfId <= $lastIndex){
    $linksWfFile=$dirInLinks."wf_myExperiment_".$wfId."_datalinks.txt";
    if(-e $linksWfFile){ #If this workflow is considered
	print(">>>Wf$wfId:\n");


$wholeGraph = Graph->new(directed => 1);  # 0 means FALSE. 1 means TRUE.
# With undirected graph, the links in the graph doesn't preserve the sense. But with directed graph, I cann't check the is_connected: FALSE. I can check if it is_weakly_connected (it means all vertices could be reached, through links follow in whatever sense, not necessarily in the sense of the edge).
# In undirected graph, I should use: $wholeGraph = Graph->new(undirected => 0, unionfind => 1); because unionfind allow to check the connectivity in a faster way.
# To create a dataGenBy structure or usesBy structure or both???
open(IN,"<$linksWfFile") or die "Couldn't open: $linksWfFile";
while(<IN>){ #foreach "link"
  
    chomp;
    @line=split("\ ->\ ",$_);
    @source=split("\:URI\:",$line[0]); # servName:URI:uriName
    @sink=split("\:URI\:",$line[1]);
    # print("source ARRAY: @source\n");
    # print("sink ARRAY: @sink\n");
    
    $sourceVar=$listURIs[$wfId]{$source[0]}{$source[1]};
    # print("sourceVar: $sourceVar\n");
    $sinkVar=$listURIs[$wfId]{$sink[0]}{$sink[1]};
    # print("sinkVar: $sinkVar\n");
    $wholeGraph->add_edge($sourceVar, $sinkVar);
} # end-while for link to add to graph
close(IN);

my $verticesNum = $wholeGraph->vertices;
print("VerticesNo.= $verticesNum\n");
my @verticesList = $wholeGraph->vertices;
#print("Vertices List= @verticesList\n");
#print("Whole graph: $wholeGraph\n");
	

# 2) to generate all possible combinations of nodes (with combinations as PowerSet): 
if($verticesNum<$minSubgraphNodes){$minReal=$verticesNum;}else{$minReal=$minSubgraphNodes;}
if($verticesNum<$maxSubgraphNodes){$maxReal=$verticesNum;}else{$maxReal=$maxSubgraphNodes;}
for my $currentSubWfSize ($minReal..$maxReal){
    @allCombinations=combinations(\@verticesList,$currentSubWfSize);
    foreach my $subset (@allCombinations){
	$fragmentGraph = $wholeGraph->subgraph([@{$subset}]);
	#print("Fragment graph: $fragmentGraph\n");

	if($fragmentGraph->is_weakly_connected) {
	    # To check if it has annotations, storing them in a structure to loop in matrix: 
	    @annotSubGraphCurrent=();
	    foreach my $node (@$subset){
		foreach my $annotUri (@{$node->{'annot'}}){
		    $matched = grep $_ eq $annotUri, @annotSubGraphCurrent;
		    if($matched == 0){
			push(@annotSubGraphCurrent,$annotUri);
		    } # end-if annot not included in array
		} # end-foreach annotation of this subgraph
	    } # end-foreach node of this connected subset/subgraph

	    # If subWf with annotations
	    if(scalar @annotSubGraphCurrent > 0){
		# To assign a name and an ID ($subwfIDhash=wfXX_subYY) + to save in a "array" of subgraphs
		$subWfCount=$subWfCount+1;
		$subWfName="wf".$wfId."_sub".$subWfCount;
		$subWfID=$indArray;
		$subWfIDhash{$subWfName}=$subWfID;
		#$subWfIDarray[$subWfID]=$subWfName; # To check if it is neccessary
		$indArray=$indArray+1;

		# To store annotations in the general array (@annotSubGraph)
		@{$annotSubGraph[$subWfID]}=@annotSubGraphCurrent;
		my $fileAnnotSubWf=$dirOut."wf_myExperiment_annotations_".$ontology."_".$subWfCount.".txt";
		open(ANNOT,">$fileAnnotSubWf") or die "Couldn't open: $fileAnnotSubWf";
 		foreach my $annotUri (@{$annotSubGraph[$subWfID]}){
 		    print(ANNOT "$annotUri\n");		    
 		} # end-foreach annotation of this subgraph
		close(ANNOT);

		# To write .gv file:
		$fileOut=$dirOut."wf_myExperiment_".$ontology."_".$wfId.".".$subWfCount.".gv";
		print_gvFile_subgraph($subWfName,$fileOut,$fragmentGraph);
		# To generate .svg file:
		$fileSvg=$dirOut."wf_myExperiment_".$ontology."_".$wfId.".".$subWfCount.".svg";
		system("dot -Tsvg $fileOut -o $fileSvg");
	    } # end-if subWf with annotations
	} # end-if $fragment is connected
    } #end-for next subset of nodes (i.e. possible combinations) (different subsets of powerset)
} #end-for subgraph size inside the limits
 } #end-if considered workflow
     $wfId=$wfId+1;    
} #end-while wfId


##############################################################
# 3.- To compute similarity matrix
# and save in a file.
my (@line1, @line2, $maxSubWfs, $sufWfID, @subWf1Annot, @subWf2Annot);
my @distanceMatrix;
@annotSubGraph=();
$maxSubWfs=0;

# To load annotations of each subWf in an array of arrays, reading from annotations files (NewAnnot/ClusteringSubgraphs/wf_myExperiment_annotations_$ont_*>).
$prefix="wf_myExperiment_annotations_".$ontology."_*";
@files=<$dirOut$prefix>; #my @files=<../Data/WF_myExperiment/NewAnnot/ClusteringSubgraphs/wf_myExperiment_annotations_$ont_*>;
foreach my $subWfFile (@files){
    @line1=split("wf_myExperiment_annotations_".$ontology."_",$subWfFile);
    @line2=split("\\.txt",$line1[1]);
    $subWfID=$line2[0];
    if($subWfID > $maxSubWfs){ 
	$maxSubWfs=$subWfID;
    } #end-if maxSubWfs
    @{$annotSubGraph[$subWfID]}=();

    open(ANNOT,"<$subWfFile") or die "Couldn't open: $subWfFile";
    while(<ANNOT>){
	chomp;
	push(@{$annotSubGraph[$subWfID]},$_);		
    } #end-while each file line
    close(ANNOT);
} # end-foreach annotation files of each subgraph

# #Print array content: This array begin at position 1.
# for my $i (1..$maxSubWfs){
#     print("Subwf $i: @{$annotSubGraph[$i]}\n");
# }


# To compute SemSim for each pair of subWfs
# The matrix is NOT symmmetric, I need to compute by complete.
# Ex: $semSimMatrix[2][14], where $subWfID1=$subWfIDarray[2] (it is something such as "wfXX.sub1") and $subWfID2=$subWfIDarray[14].
############# TO-DO: To include $DIRsml as parameter or similar.
my $DIRsml="SML_toolkit";
open(QUERIES,">".$DIRsml."/SemSimSubWfs/data/".$ontology."_queries.csv") or die "Couldn't open: queries file to write!";
open(ANNOT,">".$DIRsml."/SemSimSubWfs/data/instances_annot_".$ontology.".tsv") or die "Couldn't open: instances annot file to write!";
my ($annotSubwfString, $pwd, $count, @lineSemSim, $subWfI, $subWfJ, $semSim);
 for my $i (1..$maxSubWfs){
     $annotSubwfString = join(';',@{$annotSubGraph[$i]});
     print(ANNOT "http://graph/subwf/$i\t$annotSubwfString\n");
     for my $j (1..$maxSubWfs){
	#print("Subwf $i vs $j\n");
	if($i == $j){
	    $distanceMatrix[$i][$j]=0;
	}else{    
	    print(QUERIES "http://graph/subwf/$i\thttp://graph/subwf/$j\n");

# Old call to subroutine:
#	    @subWf1Annot=@{$annotSubGraph[$i]};
#	    @subWf2Annot=@{$annotSubGraph[$j]};
#	    $distanceMatrix[$i][$j]=1-compute_semSim_2subWfs($icMetric,$pairwiseMetric,$groupwiseMetric,$ontology,\@subWf1Annot,\@subWf2Annot); # This subroutine takes two arrays of annotations (i.e. two arrays of URIs).
#	    $distanceMatrix[$i][$j]=rand(1);
#	    print("distance[$i][$j]: $distanceMatrix[$i][$j]\n");
	} # end-if i==j (the same subWf)
    } # end-for $j
} # end-for $i
close(QUERIES);
close(ANNOT);

  #To retrieve semSimilarities
  #To get queries file
  #To call SML
  $pwd = cwd();
  chdir($DIRsml);
  system("java -DentityExpansionLimit=10000000 -jar sml-toolkit-0.8.2.jar -t sm -xmlconf SemSimSubWfs/conf_semSimSubWfs_${ontology}.xml >> SemSimSubWfs/results/outputSML_".$ontology.".txt");
  chdir($pwd);

# To parse SML toolkit results with semSimilarities and to store in $distanceMatrix
  open(RESULTS, "<$DIRsml/SemSimSubWfs/results/".$ontology."_results.csv");
  $count=1;
  while(<RESULTS>){
      if($count > 1){
	  chomp;
	  @lineSemSim=split("\\t",$_);
	  ($subWfI = $lineSemSim[0]) =~ s/http:\/\/graph\/subwf\///;
	  ($subWfJ = $lineSemSim[1]) =~ s/http:\/\/graph\/subwf\///;
	  $semSim=$lineSemSim[2];

	  $distanceMatrix[$subWfI][$subWfJ]=1-$semSim;
	  #print("semSim[$subWfI][$subWfJ]: $semSim\n");
      }
      $count=$count+1;
  } #end-while SML results file
  close(RESULTS);



#To save distance matrix in a file
my $fileOutMatrix=$dirOut."distanceMatrix_".$ontology.".txt";
open(OUT,">$fileOutMatrix") or die "Couldn't open: $fileOutMatrix";
#Print header
#print(OUT "#$subWfIDarray[0]");
print(OUT "#subWf_1");
for my $i (2..$maxSubWfs){
    #print(OUT "\t$subWfIDarray[$i]");
    print(OUT "\tsubWf_$i");
} #end-for print header
print(OUT "\n");
#Print values
for my $i (1..$maxSubWfs){
    print(OUT "$distanceMatrix[$i][1]");
    for my $j (2..$maxSubWfs){
	print(OUT "\t$distanceMatrix[$i][$j]");
    } #end-for $j
    print(OUT "\n");
} #end-for $i
close(OUT);


#Clustering:
#To write file in R
# my $fileOutClusters=$dirOut."clusters_".$ontology.".txt";
# my $fileSilGraph=$dirOut."silhouetteGraph_".$ontology.".pdf";
# open(OUT,">R_clustering_commands.r");
# print(OUT "library(cluster,quietly=TRUE)\n");
# print(OUT "library(fpc,quietly=TRUE)\n");
# print(OUT "data <- read.delim('$fileOutMatrix')\n");
# my $numClusters=int(sqrt($maxSubWfs/2));
# print("NumClusters: $numClusters\n");
# print(OUT "fitPam <- pam(data,$numClusters,diss=TRUE)\n");
# print(OUT "write.csv(fitPam\$cluster,'$fileOutClusters',quote=FALSE)\n");
# print(OUT "si<- silhouette(fitPam)\n");
# print(OUT "(ssi <- summary(si))\n");
# print(OUT "fitPam\$medoids\n");
# print(OUT "mean(fitPam\$clusinfo[,1])\n");
# print(OUT "sd(fitPam\$clusinfo[,1])\n");
# print(OUT "Mean silhouette mean: ssi\$avg.width\n");
# print(OUT "pdf('$fileSilGraph')\n");
# print(OUT "plot(si)\n");
# print(OUT "dev.off()\n");
# close(OUT);


#To write file in R
my $fileOutClusters=$dirOut."clusters_".$ontology.".txt";
my $fileSilGraph=$dirOut."silhouetteGraph_".$ontology.".pdf";
open(OUT,">R_clustering_commands.r");
print(OUT "library(cluster,quietly=TRUE)\n");
print(OUT "library(fpc,quietly=TRUE)\n");
print(OUT "data <- read.delim('$fileOutMatrix')\n");
#my $numClusters=int(sqrt($maxSubWfs/2));
#my $numClusters=4;
my $maxNumClus=ceil(0.1*$maxSubWfs);
print(OUT "fitPamBest <- pamk(data,krange=2:$maxNumClus,diss=TRUE)\n");
print(OUT "fitPam <- pam(data,fitPamBest\$nc,diss=TRUE)\n");
print(OUT "write.csv(fitPam\$cluster,'$fileOutClusters',quote=FALSE)\n");
print(OUT "si<- silhouette(fitPam)\n");
print(OUT "(ssi <- summary(si))\n");
print(OUT "fitPam\$medoids\n");
print(OUT "mean(fitPam\$clusinfo[,1])\n");
print(OUT "sd(fitPam\$clusinfo[,1])\n");
print(OUT "Mean silhouette mean: ssi\$avg.width\n");
print(OUT "pdf('$fileSilGraph')\n");
print(OUT "plot(si)\n");
print(OUT "dev.off()\n");
close(OUT);


# Run R file
my $fileOutSilAndMedoids=$dirOut."silhouetteAndMedoids_".$ontology.".txt";
system("R --no-save -q < R_clustering_commands.r > $fileOutSilAndMedoids");


# To parse clusters results
my @cluster=();
open(CLUS,"<$fileOutClusters") or die "Couldn't open: $fileOutClusters";
while(<CLUS>){
    if($_ =~ "subWf"){
	chomp;
	@line=split("\,",$_);
	$line[0]=~ s/.*subWf_//;
#	print("subwf,cluster: $line[0], $line[1]\n");
	push(@{$cluster[$line[1]]},$line[0]);
    } #end-if
} #end-while clusters file	
close(CLUS);


# To load annotations of each subWf in an array of arrays, reading from annotations files (NewAnnot/ClusteringSubgraphs/wf_myExperiment_annotations_$ont_*>).
$prefix="wf_myExperiment_annotations_".$ontology."_*";
@files=<$dirOut$prefix>; #my @files=<../Data/WF_myExperiment/NewAnnot/ClusteringSubgraphs/wf_myExperiment_annotations_$ont_*>;
foreach my $subWfFile (@files){
    @line1=split("wf_myExperiment_annotations_".$ontology."_",$subWfFile);
    @line2=split("\\.txt",$line1[1]);
    $subWfID=$line2[0];
    if($subWfID > $maxSubWfs){ 
	$maxSubWfs=$subWfID;
    } #end-if maxSubWfs
    @{$annotSubGraph[$subWfID]}=();

    open(ANNOT,"<$subWfFile") or die "Couldn't open: $subWfFile";
    while(<ANNOT>){
	chomp;
	push(@{$annotSubGraph[$subWfID]},$_);		
    } #end-while each file line
    close(ANNOT);
} # end-foreach annotation files of each subgraph

# #Print array content: This array begin at position 1.
# for my $i (1..$maxSubWfs){
#     print("Subwf $i: @{$annotSubGraph[$i]}\n");
# }



# To compute annotations frequency
my @annotPerClus=();
my $dirOutCluster;
for my $indClus (1..$numClusters){
    $dirOutCluster=$dirOut."Cluster${indClus}/";
    mkdir($dirOutCluster);
    for my $subwfID (@{$cluster[$indClus]}){
	system("cp -p ${dirOut}wf_myExperiment_*.${subwfID}.svg ${dirOutCluster}");
	for my $annot (@{$annotSubGraph[$subwfID]}){
	    if(!defined($annotPerClus[$indClus]{$annot})){
		$annotPerClus[$indClus]{$annot}++;
		$annotPerClus[$indClus]{$annot}=1;
	    }else{
		$annotPerClus[$indClus]{$annot}=$annotPerClus[$indClus]{$annot}+1;
	    }
	}
    }
}


my $uriAnnotInputFile=$dirInAnnot."wf_myExperiment_*_edamAnnotations.txt";
my $uriAnnotFile=$dirInAnnot."uri-name_annotations_".$ontology.".txt";
#print("egrep \"".$ontology."[[\:space\:]]\" $uriAnnotInputFile | awk -F'\\t' '{print \$5\"\\t\"\$4}' | sort | uniq > $uriAnnotFile");
system("egrep \"".$ontology."[[\:space\:]]\" $uriAnnotInputFile | awk -F'\\t' '{print \$5\"\\t\"\$4}' | sort | uniq > $uriAnnotFile");



my %hashUriName;
open(ANNOT,"<$uriAnnotFile") or die "Couldn't open: $uriAnnotFile";
while(<ANNOT>){
    chomp;
    @line=split("\\t",$_);
    $hashUriName{$line[0]}=$line[1];
} #end-while each file line
close(ANNOT);


my $annotFreq;
my $annotResultsFile=$dirOut."clusters_statistics_".$ontology.".txt";
open(OUT,">$annotResultsFile") or die "Couldn't open: $annotResultsFile";
print(OUT "#ClusterID\tfrequencySubwfsWithThisAnnot\tno.subwfsWithThisAnnot\tAnnotURI\tAnnotName\n");
for my $indClus (1..$numClusters){
    foreach my $annot (keys %{$annotPerClus[$indClus]}){
	$annotFreq=($annotPerClus[$indClus]{$annot}/(scalar @{$cluster[$indClus]}));
	print(OUT "$indClus\t$annotFreq\t$annotPerClus[$indClus]{$annot}\t$annot\t$hashUriName{$annot}\n");
    } #end-foreach annot in this cluster
} #end-foreach cluster
close(OUT);
# sort results by cluster and frequency, preserving header at the beginning.
system("(head -n 1 $annotResultsFile && tail -n +2 $annotResultsFile | sort -k1,2 -n)  > $annotResultsFile.bis");
system("mv $annotResultsFile.bis $annotResultsFile");



