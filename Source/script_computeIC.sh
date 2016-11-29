#!/bin/sh
# Call: sh script_computeIC.sh "../Data/WF_myExperiment/NotRedundantAnnot"

DIRannot=$1
DIRsml="SML_toolkit"
outFile="${DIRsml}/ICvalues/results/output_SMLtoolkit_allOntologies.txt"

echo "" > ${outFile} 
for ont in "EDAM" "BAO" "OBIWS" "BRO" "IAO" "MS" "MESHdesc" "MESHqual" "MESHsupp" "MESH" "OBI" "SWO" "EFO" "NCIT" "NIFSTD" "SIO"
#for ont in "GO"
do
    echo "\n***********************************************************************************************"  >> ${outFile}
    echo "${ont}" >> ${outFile}
    echo "***********************************************************************************************"  >> ${outFile}

    # 1.- To retrieve annotations
    case ${ont} in
	"MESHdesc")
	    egrep "MESH[[:space:]]D" ${DIRannot}/*edamAnnotations.txt > ${DIRsml}/ICvalues/data/${ont}_TermsInAnnotations.txt;;
	"MESHqual")
	    egrep "MESH[[:space:]]Q" ${DIRannot}/*edamAnnotations.txt > ${DIRsml}/ICvalues/data/${ont}_TermsInAnnotations.txt;;
	"MESHsupp")
	    egrep "MESH[[:space:]]C" ${DIRannot}/*edamAnnotations.txt > ${DIRsml}/ICvalues/data/${ont}_TermsInAnnotations.txt;;
	"EDAM")
	    egrep "EDAM[[:space:]]" ${DIRannot}/*edamAnnotations.txt > ${DIRsml}/ICvalues/data/${ont}_TermsInAnnotations.txt;;
	"GO")
	    echo "";;
	*)
	    egrep "${ont}[[:space:]]" ${DIRannot}/*edamAnnotations.txt > ${DIRsml}/ICvalues/data/${ont}_TermsInAnnotations.txt;;
    esac

    # 2.- To get queries file
    cd ${DIRsml}
    case ${ont} in
# 	"EDAM") #"EDAM"|"MS") For testing with a "MS_queries_withoutObsolete.csv" file	
# 	    cp ${DIRsml}/ICvalues/data/${ont}_queries_withoutObsolete.csv ${DIRsml}/ICvalues/data/${ont}_queries.csv;;
	"EDAM"|"OBIWS"|"MS")      
	    awk -F"\t" '{print $3"\t"$3}' ICvalues/data/${ont}_TermsInAnnotations.txt | sort | uniq > ICvalues/data/${ont}_queries.csv;;	    
	"BAO"|"IAO"|"OBI"|"SWO"|"MESHdesc"|"MESHqual"|"MESHsupp"|"MESH"|"SWO-EDAM"|"EFO"|"NCIT"|"NIFSTD"|"SIO")
	    awk -F"\t" '{print $5"\t"$5}' ICvalues/data/${ont}_TermsInAnnotations.txt | sort | uniq > ICvalues/data/${ont}_queries.csv;;
	"BRO")
	    awk -F"\t" '{print $5"\t"$5}' ICvalues/data/${ont}_TermsInAnnotations.txt | sort | uniq > ICvalues/data/${ont}_queries.csv;
	    egrep -v "http://www.w3.org/1999/02/" ICvalues/data/${ont}_queries.csv | egrep -v "http://www.w3.org/2004/02/skos/core"> temp_${ont}.csv;
	    mv temp_${ont}.csv ICvalues/data/${ont}_queries.csv;;
    esac

    # 3.- To compute IC values
    java -DentityExpansionLimit=10000000 -jar sml-toolkit-0.8.2.jar -t sm -xmlconf ICvalues/conf_computeIC_${ont}.xml >> ${outFile}

done

cd ${DIRsml}/ICvalues/results
rm -f all_results_ICI.csv
cat *_results_ICI.csv > all_results_ICI.csv
cp -p MESHdesc_results_ICI.csv MESH_results_ICI.csv
