use strict;
use warnings;
use Cwd;
use Graph;
use Graph::Subgraph;
use List::PowerSet qw(powerset powerset_lazy);
use File::Copy;
use POSIX;
use Switch;



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


#################################################################################################
#################################################################################################
#################################################################################################


my ($l, $lastChar, $prefix, @files, $linksWfFile, @line, @source, @sink, @subWfIDarray, $indArray, $wholeGraph, $sourceVar, $sinkVar, $fileOut, $fileSvg, @annotSubGraph, @annotSubGraphCurrent, $subWfName, $subWfID, %subWfIDhash, $matched);


my $dirInAnnot=$ARGV[0];
my $dirInLinks=$ARGV[1];
my $ontology=$ARGV[2];
my $minSubgraphNodes=$ARGV[3]; # Beginning: 2, after it could be 1, to find group of nodes similar to an isolated node. It makes specially sense when the isolated node is a nested workflow.
my $maxSubgraphNodes=$ARGV[4]; # Beginning: 3, after 4, etc.
my $kSelMeth=$ARGV[5]; # KruleThumb or KbestSilh
my $algorithmClustering=$ARGV[6]; # PAM or AGNES


my $icMetric='ICI_ZHOU_2008'; #With all ontologies: ICI_SANCHEZ_2011
my $pairwiseMetric='SIM_PAIRWISE_DAG_NODE_SCHLICKER_2006'; #or'SIM_PAIRWISE_DAG_NODE_JIANG_CONRATH_1997'
my $groupwiseMetric='SIM_GROUPWISE_BMA';
# It isn't necessary, since SMLtoolkit, with BMA, assumes 'Avg' symmetriztion.
# my $symmetrizationOperator="Avg"; # Values={Min, Max, Avg}. To combine sim(w1,w2) with sim(w2,w1). distance=1-($symmetrizationOperator(SemSim(w1,w2),SemSim(w2,w1))

print("$kSelMeth\n");

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


my $subWfCount=0; # General count, for subwf in all workflows.
@subWfIDarray=();
$indArray=0;

my $currentMeth="${kSelMeth}_${algorithmClustering}";
my $dirOutRoot=$dirInAnnot."ClusteringSubgraphs${ontology}/";
my $fileOutMatrix=$dirOutRoot."distanceMatrix_".$ontology.".txt";
my $dirOut=$dirInAnnot."ClusteringSubgraphs${ontology}/${currentMeth}/";
mkdir($dirOut);

#To write file in R
my $fileOutClusters=$dirOut."subwfClusterPairs.txt";
my $fileStatistics=$dirOut."general_statistics.txt";
my $fileSilGraph=$dirOut."silhouetteGraph_".$ontology.".pdf";
my $fileTree=$dirOut."hierarchicalTree_".$ontology.".pdf";
my $fileClustersDist=$dirOut."cluster_statistics.txt";
my $fileR=$dirOut."R_clustering_commands_".${ontology}."_".${currentMeth}."_step1.r";
open(OUT,">$fileR");
print(OUT "library(lattice,quietly=TRUE)\n");
print(OUT "library(cluster,quietly=TRUE)\n");
print(OUT "library(fpc,quietly=TRUE)\n");
print(OUT "data <- read.delim('$fileOutMatrix')\n");
print(OUT "numSubgraphs <- nrow(data)\n"); # No.Subgraphs
##########################################
# Distint part:
if($algorithmClustering eq "PAM"){
    if($kSelMeth eq "KruleThumb"){
    ### a.- KruleThumb_PAM
	print(OUT "k <- floor(sqrt(numSubgraphs/2))\n");
    }elsif($kSelMeth eq "KbestSilh"){
    ### b.- KbestSilh_PAM
        #print(OUT "maxNumClus <- ceil(0.1*numSubgraphs)\n");
        #print(OUT "fitPamBest <- pamk(data,krange=2:maxNumClus,diss=TRUE)\n");
        #print(OUT "k <- fitPamBest$nc\n");
	my $bestK;
	# Values pre-computed with previous scripts
	if($ontology eq "BAO"){
	    $bestK=104;
	}elsif($ontology eq "BRO"){
	    $bestK=5;
	}elsif($ontology eq "EDAM"){
	    $bestK=277;
	}elsif($ontology eq "EFO"){
	    $bestK=156;
	}elsif($ontology eq "IAO"){
	    $bestK=42;
	}elsif($ontology eq "MESH"){
	    $bestK=262;
	}elsif($ontology eq "MS"){
	    $bestK=20;
	}elsif($ontology eq "NCIT"){
	    $bestK=300;
	}elsif($ontology eq "NIFSTD"){
	    $bestK=280;
	}elsif($ontology eq "OBI"){
	    $bestK=13;
	}elsif($ontology eq "OBIWS"){
	    $bestK=74;
	}elsif($ontology eq "SIO"){
	    $bestK=258;
	}elsif($ontology eq "SWO"){
	    $bestK=260;
	}
	print(OUT "k <- $bestK\n");
    }else{
	print("Unknown K selection method in PAM!!\n");
    } #end-if KselMethod
    print(OUT "fitPam <- pam(data,k,diss=TRUE)\n");
    print(OUT "fitPam\$medoids\n");
    print(OUT "si <- silhouette(fitPam)\n");
}elsif($algorithmClustering eq "AGNES"){
    print(OUT "fitAgnes <- agnes(data,method='average',diss=TRUE) # method={average,single,complete,ward,weighted,flexible,gaverage}\n");	
    print(OUT "pdf('$fileTree')\n");
    print(OUT "plot(fitAgnes,which.plots=2)\n");
    print(OUT "dev.off()\n");
    if($kSelMeth eq "KruleThumb"){
    ### c.- KruleThumb_AGNES
	print(OUT "k <- floor(sqrt(numSubgraphs/2))\n");
	print(OUT "si <- silhouette(cutree(fitAgnes,k),data)\n");
    }elsif($kSelMeth eq "KbestSilh"){
    ### d.- KbestSilh_AGNES
	print(OUT "maxNumClus <- ceiling(0.1*numSubgraphs)\n");
	print(OUT "my.k.choices <- 2:maxNumClus\n");
	print(OUT "current.avgWidth <- 0\n");
	print(OUT "for (ii in (1:length(my.k.choices)) ){\n");
	print(OUT "    new.avgWidth <- summary(silhouette(cutree(fitAgnes,k=my.k.choices[ii]),data))\$avg.width;\n");
	print(OUT "    print(new.avgWidth);\n");
	print(OUT "    if(new.avgWidth > current.avgWidth){\n");
	print(OUT "	  si <- silhouette(cutree(fitAgnes,k=my.k.choices[ii]),data);\n");
	print(OUT "	  ssi <- summary(si);\n");
	print(OUT "	  current.avgWidth <- new.avgWidth;\n");	
	print(OUT "	  k <- my.k.choices[ii];\n");
	print(OUT "    }\n");
	print(OUT "}\n");
    }else{
	print("Unknown K selection method in AGNES!!\n");
    } #end-if KselMethod
    # Add prefix to the row names to identify subWfs the same as in the PAM method
    print(OUT "rownames(si) <- rownames(si, do.NULL=FALSE, prefix='subWf_')\n");
}else{
    print("Unknown clutering algorithm!!\n");
} #end-if selection algorithm
##########################################
# Common part to both algorithms and both KselMethods:
print(OUT "write.csv(si[,1],'$fileOutClusters',quote=FALSE)\n");
print(OUT "(ssi <- summary(si))\n");
# Alternative way, but just in PAM:
# print(OUT "meanClusterSize <- mean(fitPam\$clusinfo[,1])\n");
# print(OUT "meanClusterSize\n");
# print(OUT "stdClusterSize <- sd(fitPam\$clusinfo[,1])\n");
# print(OUT "stdClusterSize\n");
# print(OUT "meanSilhCoeff <- ssi\$avg.width\n"); # The same as: fitPam$silinfo[3]$avg.width
# print(OUT "meanSilhCoeff\n");
# print(OUT "stdSilhCoeff <- sd(fitPam\$silinfo[2]\$clus.avg.widths)\n");
# print(OUT "stdSilhCoeff\n");
# print(OUT "meanFreqRel <- mean(fitPam\$clusinfo[,1]/numSubgraphs)\n");
# print(OUT "meanFreqRel\n");
# print(OUT "stdFreqRel <- sd(fitPam\$clusinfo[,1]/numSubgraphs)\n");
# print(OUT "stdFreqRel\n");
print(OUT "meanClusterSize <- mean(ssi\$clus.sizes)\n");
print(OUT "meanClusterSize\n");
print(OUT "stdClusterSize <- sd(ssi\$clus.sizes)\n");
print(OUT "stdClusterSize\n");
print(OUT "meanSilhCoeff <- ssi\$avg.width\n"); # The same as: fitPam$silinfo[3]$avg.width
print(OUT "meanSilhCoeff\n");
print(OUT "stdSilhCoeff <- sd(ssi\$clus.avg.widths)\n");
print(OUT "stdSilhCoeff\n");
print(OUT "meanFreqRel <- mean(ssi\$clus.sizes/numSubgraphs)\n");
print(OUT "meanFreqRel\n");
print(OUT "stdFreqRel <- sd(ssi\$clus.sizes/numSubgraphs)\n");
print(OUT "stdFreqRel\n");
print(OUT "write.table((cbind(ssi\$clus.avg.widths,ssi\$clus.sizes,ssi\$clus.sizes/numSubgraphs)),'$fileClustersDist',sep='\\t',row.names=TRUE,col.names=FALSE,quote=FALSE)\n");
print(OUT "write(\"#numSubgraphs,numClusters,meanSilhCoeff,stdSilhCoeff,meanClusterSize,stdClusterSize,meanRelFreq,stdRelFreq\",'$fileStatistics')\n");
print(OUT "write(paste(numSubgraphs,k,meanSilhCoeff,stdSilhCoeff,meanClusterSize,stdClusterSize,meanFreqRel,stdFreqRel,sep=','),'$fileStatistics',append=TRUE)\n");
print(OUT "pdf('$fileSilGraph')\n");
print(OUT "plot(si)\n");
print(OUT "dev.off()\n");
close(OUT);

# Run R file
my $fileOutLogR=$dirOut."logR.txt";
system("R --no-save -q < $fileR > $fileOutLogR");



# To recover the final number of clusters
my $numClusters;
chomp($numClusters = qx(tail -n1 $fileStatistics | cut -d, -f2));

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
my (@line1, @line2, $maxSubWfs);
chomp($maxSubWfs = qx(head -n1 $fileOutMatrix | awk -F'\t' '{print NF}'));
$prefix="wf_myExperiment_annotations_".$ontology."_*";
@files=<$dirOutRoot$prefix>; #my @files=<../Data/WF_myExperiment/NewAnnot/ClusteringSubgraphs/wf_myExperiment_annotations_$ont_*>;
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
my $pathSubgraphs;
for my $indClus (1..$numClusters){
    $dirOutCluster=$dirOut."Cluster${indClus}/";
    mkdir($dirOutCluster);
    for my $subwfID (@{$cluster[$indClus]}){
	$pathSubgraphs="${dirInAnnot}ClusteringSubgraphs${ontology}/wf_myExperiment_*.${subwfID}.svg";
	system("cp -p $pathSubgraphs ${dirOutCluster}");
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
system("egrep \"".$ontology."[[\:space\:]]\" $uriAnnotInputFile | awk -F'\\t' '{print \$5\"\\t\"\$4}' | sort | uniq > $uriAnnotFile");
 
 
my %hashUriName;
open(ANNOT,"<$uriAnnotFile") or die "Couldn't open: $uriAnnotFile";
while(<ANNOT>){
    chomp;
    @line=split("\\t",$_);
    $hashUriName{$line[0]}=$line[1];
} #end-while each file line
close(ANNOT);


my ($annotFreq, $totAnnotFreq);
my @clusters_numAnnot=();
my @clusters_avgFreqAnnot=();
my $annotResultsFile=$dirOut."annotations_statistics_".$ontology.".txt";
my $contAnnot=0;
open(OUT,">$annotResultsFile") or die "Couldn't open: $annotResultsFile";
print(OUT "#ClusterID\tfrequencySubwfsWithThisAnnot\tnumSubwfsWithThisAnnot\tAnnotURI\tAnnotName\n");
for my $indClus (1..$numClusters){
    $totAnnotFreq=0.0;
    foreach my $annot (keys %{$annotPerClus[$indClus]}){
	$annotFreq=($annotPerClus[$indClus]{$annot}/(scalar @{$cluster[$indClus]}));
	$totAnnotFreq=$totAnnotFreq+$annotFreq;
	print(OUT "$indClus\t$annotFreq\t$annotPerClus[$indClus]{$annot}\t$annot\t$hashUriName{$annot}\n");
	$contAnnot++;
    } #end-foreach annot in this cluster
    $clusters_numAnnot[$indClus]=(scalar keys %{$annotPerClus[$indClus]});
    if($clusters_numAnnot[$indClus] > 0){
	$clusters_avgFreqAnnot[$indClus]=($totAnnotFreq/$clusters_numAnnot[$indClus]);
    }else{
	$clusters_avgFreqAnnot[$indClus]=0;
    }
} #end-foreach cluster
close(OUT);
my $avgAnnotPerClus=($contAnnot/$numClusters);
# sort results by cluster and frequency, preserving header at the beginning.
system("(head -n 1 $annotResultsFile && tail -n +2 $annotResultsFile | sort -k1,2 -n)  > $annotResultsFile.bis");
system("mv $annotResultsFile.bis $annotResultsFile");



# To compute number of different workflows per cluster
my (@line3, %wfsInCluster, $sumDiffWfs, $wfId, $subWfId);
my @clusters_numDiffWorkflows=();
my @clusters_stringDiffWorkflows=();
%wfsInCluster=();
$sumDiffWfs=0;
for my $indClus (1..$numClusters){
    $clusters_numDiffWorkflows[$indClus]=0;
    %wfsInCluster=();
    @files=<${dirOut}Cluster${indClus}/*>;
    foreach my $subWfFile (@files){
	# To retrieve the workflow source from the .svg file nme
	@line1=split("wf_myExperiment_".$ontology."_",$subWfFile);
	@line2=split("\\.svg",$line1[1]);
	@line3=split("\\.",$line2[0]);
	$wfId=$line3[0];
	$subWfId=$line3[1];
	if(!defined($wfsInCluster{$wfId})){
	    $wfsInCluster{$wfId}++;
	} # end-if
    } # end-foreach subWfFile

    $clusters_numDiffWorkflows[$indClus]=(scalar keys %wfsInCluster);
    $clusters_stringDiffWorkflows[$indClus] = join(",", map { "$_" } sort {$a<=>$b} keys %wfsInCluster);

    $sumDiffWfs=$sumDiffWfs+$clusters_numDiffWorkflows[$indClus];
} # end-foreach cluster
my $avgDiffWfsPerClus=($sumDiffWfs/$numClusters);


# To write cluster statistics file
open(OUT,">$fileClustersDist.bis");
open(IN,"<$fileClustersDist") or die "Couldn't open: $fileClustersDist";
print(OUT "#ClusterID\tMeanSilh\tSize\tRelFreq\tNumAnnot\tAvgAnnotFreq\tNumDiffWfs\tStringDiffWfs\n");
my $indClus;
while(<IN>){
    chomp;
    # '$_' includes the first three fields: ClusterID, meanSilh and size
    @line=split("\\t",$_);
    $indClus=$line[0];
    print(OUT "$_\t$clusters_numAnnot[$indClus]\t$clusters_avgFreqAnnot[$indClus]\t$clusters_numDiffWorkflows[$indClus]\t$clusters_stringDiffWorkflows[$indClus]\n");    
} # end-while
close(IN);
close(OUT);
system("mv $fileClustersDist.bis $fileClustersDist");
unlink("$fileClustersDist.bis");


# To compute correlations: to compute Pearson correlation between silhouette and cluster size, silhouette and number of annotations; and silhouette and average frequency of annotations.
my $fileCorrelations=$dirOut."correlations.txt";
my $fileCorrelationGraph=$dirOut."correlationGraphs.pdf";
$fileR=$dirOut."R_clustering_commands_".${ontology}."_".${currentMeth}."_step2.r";
open(OUT,">$fileR");
print(OUT "clusInfo <- read.delim('$fileClustersDist')\n");
print(OUT "clusInfo <- clusInfo[,c('MeanSilh','Size','NumAnnot','AvgAnnotFreq')]\n"); # Select just the columns we are interested in.
#print(OUT "clusInfo\$StringDiffWfs <- NULL\n"); # To delete last column with a string, to allow cor() works.
print(OUT "corrMatrix <- cor(clusInfo)\n");
print(OUT "write(paste(corrMatrix['MeanSilh','Size'],corrMatrix['MeanSilh','NumAnnot'],corrMatrix['MeanSilh','AvgAnnotFreq'],sep=','),'$fileCorrelations')\n");
print(OUT "pdf('$fileCorrelationGraph',height=4,width=12)\n");
print(OUT "par(mfrow=c(1,3)) # Figure with 3 graphs, placed in 1 row and 3 columns\n");
print(OUT "plot(clusInfo\$Size,clusInfo\$MeanSilh,ylab='silhouette',xlab='cluster size',main=paste('Pearson corr.=',round(corrMatrix['MeanSilh','Size'],4)))\n");
print(OUT "plot(clusInfo\$NumAnnot,clusInfo\$MeanSilh,ylab='silhouette',xlab='no.annotations',main=paste('Pearson corr.=',round(corrMatrix['MeanSilh','NumAnnot'],4)))\n");
print(OUT "plot(clusInfo\$AvgAnnotFreq,clusInfo\$MeanSilh,ylab='silhouette',xlab='avg.annotation frequency',main=paste('Pearson corr.=',round(corrMatrix['MeanSilh','AvgAnnotFreq'],4)),xlim=range(0:1))\n");
print(OUT "dev.off()\n");
close(OUT);
# Run R file
system("R --no-save -q < $fileR >> $fileOutLogR");


# To complete general statistics file with: average annotations, diffWorkflows and correlations
my $stringCorrelations;
chomp($stringCorrelations = qx(head -n1 $fileCorrelations));
open(OUT, ">$fileStatistics.bis");
open(IN, "<$fileStatistics") or die "Couldn't open: $fileStatistics";
while(<IN>){
    chomp;
    if($_ =~ "^#"){
	print(OUT "$_,meanNumAnnot,meanDiffWfs,corrSilhVsSize,corrSilhVsNumAnnot,corrSilhVsAnnotFreq\n");
    }else{
	print(OUT "$_,$avgAnnotPerClus,$avgDiffWfsPerClus,$stringCorrelations\n");
    } # end-if
} # end-while
close(IN);
close(OUT);
system("mv $fileStatistics.bis $fileStatistics");
unlink("$fileStatistics.bis");

