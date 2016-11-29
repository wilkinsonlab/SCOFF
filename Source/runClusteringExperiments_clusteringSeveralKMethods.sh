#!/bin/sh
# Call: sh runClusteringExperiments_clusteringSeveralKMethods.sh "../Data/WF_myExperiment/NewAnnot" "../Data/WF_myExperiment/NotRedundantAnnot" 2 3

DIRannot=$1
DIRannotNotRedund=$2
minSize=$3
maxSize=$4

for ont in "BAO" "BRO" "EDAM" "EFO" "IAO" "MESH" "MS" "NCIT" "NIFSTD" "OBI" "OBIWS" "SIO" "SWO"
do
    echo "${ont}================================================"
    for kmet in "KruleThumb" "KbestSilh"
    do
	for alg in "PAM" "AGNES"
	do
	    echo "--------------------${kmet}_${alg}--------------------------------"
	    perl retrieveAndClusterSubgraphs_perOntology_pruebaSML_partClusteringAndStatistics_severalKmethods.pl ${DIRannot} ${DIRannotNotRedund} ${ont} ${minSize} ${maxSize} ${kmet} ${alg}
	done
    done
done
