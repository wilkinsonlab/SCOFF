#!/bin/sh
# Call: sh runFragmentation_severalOntolgies.sh "../Data/WF_myExperiment/NewAnnot" "../Data/WF_myExperiment/NotRedundantAnnot" 2 3

DIRannot=$1
DIRannotNotRedund=$2
minSize=$3
maxSize=$4

for ont in "BAO" "BRO" "EDAM" "EFO" "IAO" "MESH" "MS" "NCIT" "NIFSTD" "OBI" "OBIWS" "SIO" "SWO"
do
    echo "${ont}================================================"
    perl retrieveAndClusterSubgraphs_perOntology.pl ${DIRannot} ${DIRannotNotRedund} ${ont} ${minSize} ${maxSize} ${kmet} ${alg}
done
