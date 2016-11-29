# Call: perl downloadWF_myExperiment_Peregrine.pl <dirOutFile> [<additionalTerms.txt>]
# Example: perl downloadWF_myExperiment_Peregrine.pl ../Data/WF_myExperiment additionalBioinfoTerms.txt

# Description: This program generates a list with all the available workflows related to Bioinformatics in myExperiment. Taking the definition file (short xml file). It searches for bioinformatics topics (from EDAM)+additionalTerms in the fields description, title and tags, according to the Peregrine software search conditions.
# Parameters: - First: name of the directory where all the definition files are.
#             - Second: file with additional terms to take into account in the filter of Bioinformatics workflows. One term per line. To add to the list obtained from 'edamdef'.

use strict;
use warnings;
use XML::Simple;
use XML::LibXML;
use URI::Escape;
use LWP::UserAgent;

my $dirPeregrine="Peregrine";
my $fSKOS="$dirPeregrine/edamBioinfoTerms.ttl";
# Building output directory
my $dirOut=$ARGV[0];
my $includeAdditionalTerms=0;
my $l=length($dirOut);
my $lastChar=substr($dirOut,$l-1,$l);
if($lastChar ne '/'){
    $dirOut=$dirOut."/";
} #end-if
# Check if the output directory already exists
if(!(-d $dirOut)){
    mkdir($dirOut);
}

if((scalar @ARGV) > 1){
    $includeAdditionalTerms=1;
    $fSKOS="$dirPeregrine/edamAndAdditionalBioinfoTerms.ttl";
}

# Naming output files
my $fileWFlist=$dirOut."workflowsList.xml";
my $fTemp=$dirOut."temp_downloadWF.xml";
my $rootPathWorkflowList="http://www.myexperiment.org/workflows.xml?num=100&page=";
my $rootPathSingleWF="http://www.myexperiment.org/workflow.xml?";
my $pathDefWF=$dirOut."def_wf_myExperiment_";
my $pathFileWF=$dirOut."wf_myExperiment_";

my $ua = LWP::UserAgent->new;
my $ua2 = LWP::UserAgent->new;
my $response;

# A.- Obtain list of workflows.
unlink($fileWFlist); #To delete if the file exists.
unlink($fTemp);
open(OUT,">>$fileWFlist");
binmode OUT, ":utf8"; #To avoid warning message: "Wide character in print at..."
print(OUT "<?xml version=\"1.0\"?>\n");
print(OUT "<workflows>\n");
my $remainderWF=1;
my $numPage=1;
my ($path,@line,$fNameDef,$type,$fNameWF);
while($remainderWF){
  $path=$rootPathWorkflowList.$numPage;
  $response = $ua->get($path);
  if ($response->is_success) {
    # Other option:    @listWF=split('</workflow>>\n',$response->decoded_content);
     # It should be improved: If the line is longer than 255, it could be not taken the whole line.
     open(F,">$fTemp");
     binmode F, ":utf8"; # To avoid warning message: "Wide character in print at..."
     print(F $response->decoded_content);
     close(F);
 
     open(F,"<$fTemp");
     while(<F>){
       @line=split("\</workflow>",$_);
       if($line[0] =~ "  <workflow resource"){
 	print(OUT "$line[0]</workflow>\n");
       }elsif($line[0]  =~ "<workflows/>"){
 	# To check if there is the last http request (no more workflows)	
 	$remainderWF=0;
 	print("number of pages=",$numPage,"\n");
       } #end-if
     } #end-while file
     close(F);
     unlink($fTemp);
   }else{
     die $response->status_line;
   } # end-if-ok
 
   $numPage=$numPage+1;
 } # end-while
 print(OUT "</workflows>");
 close(OUT);
 
 
 # A.- To get a document per workflow, with tags, title and description.
 # IMPORTANT ISSUES:
 # - It take directly the definition files downloaded previously with downloadWFmyExperiment.pl
 # - To take into account that all definition files are only Taverna 1 or 2 formt.
 # - Tags, title and description appear like they are, without LOWERCASE as we dd with my self BioInf filter) of each Taverna 1 and Taverna2 type (type id's 1 ad 2). Although EDAM terms will be as lowercase, since all terms begin with capitl letters with not reason.
 
 # Retrieve content-uri of each workflow (try with id and http://www.myexperimen.org/workflow.xml?id=XXXX&elements=content-uri)
my $parserWfList = XML::LibXML->new();
my $treeWfList = $parserWfList->parse_file($fileWFlist);
my $rootWfList = $treeWfList->getDocumentElement;
my ($uri, $line, $id);
my $wfId;
my ($parser, $tree, $root, $wfTag, $wfTitle, $wfDesc, $wfListFile, $wfInfoFile);
$wfListFile="$dirPeregrine/list_workflows_tagTitleDescription_files.txt";
open(LIST,">$wfListFile");
 
 # Loop through all the workflow line description
 foreach my $workflow ($rootWfList->findnodes('/workflows/workflow')){
     $uri=$workflow->getAttribute("uri");
     @line=split("id=",$uri);
     $wfId=$line[1];
 #
   print("id=$wfId\t\t");
 #
   # 1.-Download workflow definition file (main xml)
   $path=$rootPathSingleWF."id=".$wfId;
   $fNameDef=$pathDefWF.$wfId.".xml";
   $response = $ua->mirror($path,$fNameDef);
   if ($response->is_success) {     
     # With XML::LibXML:
     my $parser = XML::LibXML->new();
     my $tree = $parser->parse_file($fNameDef);
     my $root = $tree->getDocumentElement;
 
     @line=split("\/",$root->findnodes('/workflow/type/@resource')); #Ex: http:/www.myexperiment.org/content_types/2
     $type=$line[$#line]; # Take last element in the array, that is the type (1(averna 1) or 2(Taverna 2)).
         
     if(($type == 1) || ($type == 2)){ # Taverna 1 or Taverna 2 format
 	# a.- Download SCUFL or T2FLOW files with complete workflow
 	if($type == 1){     # Taverna 1: .xml
 	    $fNameWF=$pathFileWF.$wfId.".xml";
 	}elsif($type == 2){ # Taverna 2: .t2flow
 	    $fNameWF=$pathFileWF.$wfId.".t2flow";
 	}
 	$path=$root->findnodes('/workflow/content-uri/text()')->to_literal;
 	$ua2->mirror("$path",$fNameWF);
 	
 	# b.- Generate text file with tags, title and description.
 	$wfInfoFile="$dirPeregrine/workflow_tagTitleDescription_$wfId.txt";
 	print(LIST "$wfInfoFile\n"); # To write in list of files
 	open(OUT,">$wfInfoFile");
 	binmode OUT, ":utf8";
 	# To print tags, title and description in an independent file.
 	foreach my $tagID ($root->findnodes('/workflow/tags/tag/text()')){
 	    $wfTag=$tagID->to_literal;
 	    print(OUT "$wfTag\n");
 	} #end-foreach
 	    
 	$wfTitle=$root->findnodes('/workflow/title/text()');
 	$wfTitle =~ s/.xml$//;
 	$wfTitle =~ s/-/ - /g;
 	print(OUT "$wfTitle\n");    
 	$wfDesc=$root->findvalue('/workflow/description');
 	$wfDesc =~ s/:/: /g;
 	print(OUT "$wfDesc\n");
 	close(OUT);
     }else{ # Not selected type (1 or 2)
 	# To remove definition file
 	unlink($fNameDef);
 	print("Not Taverna 1 or 2 format\n");
     }
   }else{
      die $response->status_line;
   } # end-if-WFdefOK
 } # end-for WF list
 close(LIST);


 # B.- Retrieve list of terms related to bioinformatics, to filter workflows later:
        # *** Should it select also terms from other namespace, such as operation or entity?
 # Call to system to retrieve updated EDAM terms:
 my $fedamTerms=$dirOut."edamdef_bioinformatics.excel";
 my @edamArray = (); # Delete the array.
 # To obtain EDAM terms to filter
 system("edamdef -namespace topic -oformat2 excel -subclasses -query bioinformatics -outfile $fedamTerms -auto");
 # Parser the EDAM .excel file with results from edamdef, retrieving 3rd column ("name").
 my ($term, %hashIdTerm, $numEdam, $cont);
 open(IN,"<$fedamTerms");
 while(<IN>){
     chomp;
     @line=split("\\t",$_);
     # Put each EDAM selected term (3rd column) in an array position.
     $term=lc($line[2]);
     # Next if avoids to include very general terms:
     if($includeAdditionalTerms == 1){
 	if(($term ne "workflows") && ($term ne "rna") && ($term ne "structure") && ($term ne "threading") && ($term ne "text mining") && ($term ne "ontologies")){
 	    push(@edamArray,$term);
 	    $numEdam = $line[0];
 	    $numEdam =~ s/^000//;
 	    $hashIdTerm{$term}="$line[1]_$numEdam";
 	} # if term not avoided
     }else{
 	push(@edamArray,$term);
 	$numEdam = $line[0];
 	$numEdam =~ s/^000//;
 	$hashIdTerm{$term}="$line[1]_$numEdam";
     } # end-if includedAdditionaTerms
 } #end-while file edam
 close(IN);
 # Add additional terms to the array. These terms come from the user, stored in a file.
 if($includeAdditionalTerms == 1){
     my $fadditionalTerms=$ARGV[1];
     open(IN,"<$fadditionalTerms");
     $cont=1;
     while(<IN>){
 	chomp;
 	$term=lc($_);
 	push(@edamArray,$term);
 	$hashIdTerm{$term}="add_$cont";
 	$cont=$cont+1;
     } #end-while file additional terms
     close(IN);
 } # end-if additional Terms
 
 #@edamArray=sort(@edamArray);
 
 
 # C.- To write taxonomy in SKOS format, directly with EDAM 190 terms -substract + additional terms, according to this schema:
 # edam/additional:C10007 skos:inScheme vocab:EDAM/default ;
 #  		  rdfs:label "EDAM:data_0007" ; 
 #  		  prop:prefLabel_CI_NO "Tool" ; 
 #  		  a skos:Concept .
 my ($idTerm);
 open(OUT, ">$fSKOS") || die "Can't open '$fSKOS'";
 # To print header.
 print(OUT "\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n");
 print(OUT "\@prefix skos: <http://www.w3.org/2004/02/skos/core#> .\n");
 print(OUT "\@prefix dct: <http://purl.org/dc/terms/> .\n");
 print(OUT "\@prefix prop: <http://rdf.biosemantics.org/emco/properties/> .\n");
 print(OUT "\@prefix vocab: <http://rdf.biosemantics.org/emco/v1.5/vocabularies/> .\n");
 print(OUT "\@prefix edam: <http://edamontology.org/> .\n");
 print(OUT "\@prefix additional: <http://additionalTerms/> .\n");
 print(OUT "\n");
 print(OUT "prop:prefLabel_CI rdfs:subPropertyOf skos:prefLabel .\n");
 print(OUT "prop:prefLabel_NO rdfs:subPropertyOf skos:prefLabel .\n");
 print(OUT "prop:prefLabel_CI_NO rdfs:subPropertyOf skos:prefLabel .\n");
 print(OUT "\n");
 print(OUT "vocab:EDAM dct:title \"EDAM ontology\" ;\n");
 print(OUT "\t\ta skos:ConceptScheme .\n");
 print(OUT "\n\n");
 # To print a SKOS instance per each term
 foreach $term (@edamArray){
     $idTerm=$hashIdTerm{$term};
     if((grep(/^add_/,$idTerm)) == 1){
 	print(OUT "additional:$idTerm skos:inScheme vocab:default ;\n");
 	print(OUT "\t\trdfs:label \"$idTerm\" ;\n");
     }else{
 	print(OUT "edam:$idTerm skos:inScheme vocab:EDAM ;\n");
 	print(OUT "\t\trdfs:label \"EDAM:$idTerm\" ;\n");
     }
     print(OUT "\t\tprop:prefLabel_CI_NO \"$term\" ;\n");
     print(OUT "\t\ta skos:Concept .\n");
     print(OUT "\n");
 } # end-foreach bioinfo term
 close(OUT);
 
# To call to Peregrine
chdir($dirPeregrine);
system("java -Dperegrine.config.location=".$dirPeregrine."/production.properties -jar peregrine-skos-cli_0.0.3.jar ".$fSKOS." list_workflows_tagTitleDescription_files.txt outputPeregrine_wf_myExperiment_2014.03.15.ttl | cat > outputPeregrine_wf_myExperiment_2014.03.15.log"); # without log error (> instead of <&)

# To recover list of bioinformatics workflows and to load their ids in hash
# It doesn't work: system("awk -F\"  \" '{print $3}' outputPeregrine_wf_myExperiment_2014.03.15.ttl | sort | uniq | awk -F\"/\" '{print $NF}' | cut -d_ -f3 | sed \"s/.txt> \.//\" | sort -n > $wfBioinfListFile");
my (@line, @line1, @line2, @line3, $lastInd, $wfId);
my %hashWfBioinfList;
open(IN,"<$dirPeregrine/outputPeregrine_wf_myExperiment_2014.03.15.ttl");
while(<IN>){
    @line=split("  ",$_);
    @line1=split("/",$line[2]);
    $lastInd=$#line1;
    @line2=split("\\_",$line1[$lastInd]);
    @line3=split(".txt",$line2[2]);
    $wfId=$line3[0];
    if(!defined($hashWfBioinfList{$wfId})){
 	$hashWfBioinfList{$wfId}++;
    } # end-if !defined
} # end-while
close(IN);

# To remove workflows files not selected as bioinformatic-related
my $prefix="wf_myExperiment_*";
my @files=<$dirOut$prefix>; #my @files=<../Data/WF_myExperiment_2014.03.15/wf_myExperiment_*>;

my (@line4,@line5);
foreach my $wfDefFile (@files){
    @line4=split($prefix,$wfDefFile);
    @line5=split("\\.",$line4[1]);
    $wfId=$line5[0];
    
    if(!defined($hashWfBioinfList{$wfId})){
	unlink($wfDefFile);
    } # end-if !defined
} # end-foreach wfFiles


