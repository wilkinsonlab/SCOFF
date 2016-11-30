# SemSubWf
==================================
SemSubWf (Semantic SubWorkflows) automatically annotates workflows with semantic terms and returns subworkflows - clusters of semantically similar bioinformatics workflow fragments to promote workflow repair and construction.

This site describes our output result structure, includes the source code of the SemSubWf system and briefly explains how to use it.

## Output results structure ##
This section describes the different types of output files from our analysis of myExperiment workflows using SemSubWf.  

The output resources are distributed from the following URL, and folder structure(http://biordf.org/myExperiment_Annotations/) :
 1. **abstract_workflows/**:  Partially abstracted workflows (i.e. after removing non-biologically-meaningful steps) in
Taverna formats. They are the input of the automatic annotation step.
 2. **OPMW/**:  Semantic annotations of all the services within every bioinformatics-oriented myExperiment workflow (in the standard OPMW format).  
 These RDF output files include an instance of the `opmw:WorflowTemplateProcess` model for each non-shim available service of each annotated bioinformatics workflow (when each annotation in represented as an `<rdf:type rdf:resource=URI/>` property. Using these RDF file, our annotations are available and could be easily integrated in other systems requiring structured annotations of bioinformatic services.
 3. **SemSubWf/**: 
  * **ClusteringSubgraphsBAO/** 
      * **KbestSilh_AGNES/**
          * **Cluster1/**  
          ...  
          * **Cluster104/**  
          annotations_statistics_BAO.txt  
          cluster_statistics.txt
      * **KbestSilh_PAM/**
      * **KruleThumb_AGNES/**
      * **KruleThumb_PAM/**
  * **ClusteringSubgraphsBRO/**  
  ...  
  * **ClusteringSubgraphsSWO/**
 
Multiple sets of workflow fragments grouped by semantic similarity in their annotations, based on 13 different ontologies and structure vocabularies (BAO, BRO, EDAM, EFO, IAO, MeSH, MS, NCIT, NIFSTD, OBI, OBIWS, SIO and SWO) from BioPortal and 4 clustering criteria (`KbestSilh_AGNES, KbestSilh_PAM, KruleThumb_AGNES and KruleThumb_PAM`). These subdirectories include searchable text summary files (`annotations_statistics_<ontID>.txt` and `cluster_statistics.txt`) and visual representations of the clustered workflow fragments in .svg format (`wf_myExperiment_<ontID>_<wfID>.<fragmentID>.svg`) to allow simple seearch for fragments related to desired term/s, either for new workflow creation or to repair a broken workflow.



## Basic Usage ##
A brief description and instructions for how and in which order to run the different SemSubWf scripts. More details are available in the code comments of each script.

### Step 1: Automatic annotation of bioinformatics workflows with biomedical ontologies ###
 
```r
# 1.1.- Download workflows related to bioinformatics, assisted by the text mining Peregrine tool (https://trac.nbic.nl/data-mining/)
perl downloadWF_myExperiment_Peregrine.pl "<output directory (where saving workflow definition files)>" "[<additional terms filtering bioinformatics workflows>]"
# e.g. perl downloadWF_myExperiment_Peregrine.pl "../Data/WF_myExperiment" additionalBioinfoTerms.txt

# 1.2.- Clean 'shims' services and annotate
perl script_cleanShimsAndAnnotate.pl "<in/output directory (with workflows)>"
# e.g. perl script_cleanShimsAndAnnotate.pl "../Data/WF_myExperiment"

# 1.3.- To remove redundant annotations
perl processAnnotations.pl "<dirInAnnotations>"
# e.g. perl processAnnotations.pl "$HOME/Data/WF_myExperiment"

# 1.4.- Generate ttl and xml OPMW files
perl loop_generateAnnotationsInOPMW.pl "<dirInWithoutShimsWf>" "<dirInOutAnnotations>" "[<dirInRedundantAnnotations>]" "[<pathTemplate_pairsURIannot-ICvalueFiles>]" "[[<TestWfID>]]"
# e.g. perl loop_generateAnnotationsInOPMW.pl "../Data/WF_myExperiment" "../Data/WF_myExperiment/NotRedundantAnnot" > "../Results/count_nodesAndLinks_perWf.txt"

# 1.5.- Computation IC values
sh script_computeIC.sh "<dirInAnnotations>"
# e.g. sh script_computeIC.sh "../Data/WF_myExperiment/NotRedundantAnnot"
perl computeICperServiceAndWf.pl "<dirInAnnotations>" "<template ICvalue per individual annotation>" "<Output-IntermediateFile>" "<Output-Wf and Service IC withIN redundant>"
# e.g. perl computeICperServiceAndWf.pl "../Data/WF_myExperiment/NotRedundantAnnot/" "SML_toolkit/ICvalues/results/XXX_results_ICI.csv" "wf_service_annotation_IC.txt" "wfAndServiceIC.txt"
```

### Step 2: Fragmentation and Clustering based on Semantic Similarity ###
```r
# 2.1.- Fragmentation and computing subgraphs distance matrix
# It needs the SML tookit (http://www.semantic-measures-library.org/sml/) with the configuration files provided in 'SML_toolkit/' folder
sh runFragmentation_severalOntolgies.sh "<dirInAnnot>" "<dirInLinks>" "<minSizeSubgraph>" "<maxSizeSubgraph>"
# e.g. sh runFragmentation_severalOntolgies.sh "../Data/WF_myExperiment/NewAnnot" "../Data/WF_myExperiment/NotRedundantAnnot" 2 3 

# 2.2.- Clustering subgraphs
# It calls 52 times (13 ontologies X 2 clustering algorithms X 4 K selection methods) the script retrieveAndClusterSubgraphs_perOntology_partClusteringAndStatistics_severalKmethods.pl
sh runClusteringExperiments_clusteringSeveralKMethods.sh "<dirInAnnot>" "<dirInLinks>" "<minSizeSubgraph>" "<maxSizeSubgraph>"
# e.g. sh runClusteringExperiments_clusteringSeveralKMethods.sh "../Data/WF_myExperiment/NewAnnot" "../Data/WF_myExperiment/NotRedundantAnnot" 2 3
```

The input for the automatic annotation step are workflows in Taverna 1 (.xml) or 2 (.t2flow) format, in principle, from myExperiment [resource number 1, from the previous section]. The output of this first step are workflows with semantic annotations in OPMW format, corresponding to the input of the second step: fragmentation and clustering based on Semantic Similarity [resource number 2]. Finally, the output of the second step are the different subworkflows or clustered workflow fragments [resource number 3].


**Citations:**  
Identifying Bioinformatics SubWorkflows with SemSubWf: Clustering based on Semantic Similarity  
Beatriz García-Jiménez and Mark D Wilkinson  
*(Under review)*

