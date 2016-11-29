# Call: perl getDescriptionAndAnnotateWf.pl <Input-workflowFile.xml or .t2flow> <Output-listServicesWithEDAM terms>
# Example: perl getDescriptionAndAnnotateWf.pl output.t2flow salAnnotate.txt

use strict;
use warnings;
use XML::LibXML;
use LWP::UserAgent;
use URI::Escape;
use XML::Parser; 
use File::Basename;


my $fileIn=$ARGV[0];
my $fileOut=$ARGV[1];

# Login to BioPortal (http://bioportal.bioontology.org/login) to get your API key 
my $API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'


# Subroutines
#sub parse_annotator_response($$$);
#sub lookfor_ontology_terms($$);
#sub get_well_formed_biocatalogue_response($$);
#sub obtain_description_WSDL($$);
#sub obtain_description_SOAP($$);

# Subroutines
################################################################
# parse_annotator_response
################################################################
sub parse_annotator_response {
  # Parameters
  my ($res, $parser, $file) = @_;

  my ($results, $node);
  my $dom = $parser->parse_string($res->decoded_content);
  my $root = $dom->getDocumentElement();

  my ($domLabel, $rootLabel, $resLabel);
  my (@line, $urlTerm, $idTerm, $labelTerm, $hrefTerm, $urlOnt, $ontTerm);
  my $uaAnnot = new LWP::UserAgent;
  my $parserLabel = XML::LibXML->new();
  my $reqLabel = new HTTP::Request;
  $reqLabel->method("GET");

  # my $URL = "http://data.bioontology.org/ontologies/"; # It is included in href term. It doesn't neccesary to get it individually.

# This block of two sentences work!!!
#  my $queryTerm='OBIWS/classes/http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FOBIws_0000178?format=xml&apikey='.$API_KEY;
#  my $req = new HTTP::Request GET => 'http://data.bioontology.org/ontologies/'.$queryTerm;

  open(FILE,">>$file") or die "Couldn't open: $file";
  print(FILE "Ontology annotations:\n");
  $results = $root->findnodes('/annotationCollection/annotation');
  foreach $node ($results->get_nodelist){
      # a) Get id of the ontology term
      $urlTerm=$node->findvalue('annotatedClass/id');
      @line = split("\\/",$urlTerm);
      $idTerm = $line[$#line];

      # b) Get name of the ontology term
      $urlOnt=($node->findnodes('annotatedClass/linksCollection/links/ontology'))[0]->getAttribute("href");
      @line = split("\\/",$urlOnt);
      $ontTerm=pop(@line);         # The same as: $ontTerm=$line[$#line];
      
      # c) Get label (i.e. short description) of the ontology term
      $hrefTerm=($node->findnodes('annotatedClass/linksCollection/links/self'))[0]->getAttribute("href"); 
      # $hrefTerm='http://data.bioontology.org/ontologies/OBIWS/classes/http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FOBIws_0000178'; # Example.
      $reqLabel->uri($hrefTerm.'?format=xml&apikey='.$API_KEY);
      $reqLabel->content_type('application/x-www-form-urlencoded');
      # send request and get response.
      $resLabel = $uaAnnot->request($reqLabel);
      if ($resLabel->is_success) {
	  # read XML file
	  $domLabel = $parserLabel->parse_string($resLabel->decoded_content);
	  $rootLabel = $domLabel->getDocumentElement();
	  $labelTerm = $rootLabel->findvalue('/class/prefLabel');
      }else{
	  print("BAD call: ".$resLabel->content."\n");
#	  die $resLabel->status_line;
      }

      print("\t".$ontTerm."\t".$idTerm."\t".$labelTerm."\t".$urlTerm."\n");
      print(FILE "\t$ontTerm\t$idTerm\t$labelTerm\t$urlTerm\n");
  } # end foreach associated term in an ontology
  close(FILE);
}


################################################################
# sub lookfor_ontology_terms
################################################################
sub lookfor_ontology_terms($$){
  # Use: lookfor_ontology_terms($description,$fileOut);
  # Parameters
#  my ($desc, $fileOut) = @_;
  my $desc = shift;  
  my $fileOut = shift;  
   
  my $AnnotatorURL = 'http://data.bioontology.org/annotator';
  my $text = uri_escape_utf8("$desc");
	    
  my $uaAnnot = new LWP::UserAgent;
  $uaAnnot->agent('Annotator Client Example - Perl');
	    
  # create a POST request
  my $req = new HTTP::Request POST => "$AnnotatorURL";
  $req->content_type('application/x-www-form-urlencoded');
  
  my $format = "xml"; #xml, tabDelimited, text

  # Set parameters
  # Check docs for extra parameters
  $req->content(""
		#                         "longestOnly=true&"   # This parameter was removed due to inability to perform longestOnly on a set of ontologies. mgrep does longest work across the entire dictionary.
		#			 ."wholeWordOnly=true&"  # We do not have this flag at the moment and I am not sure of what the expected behavior is here. I have created a ticket to investigate this.
		#			 ."withContext=true&"
		#			 ."filterNumber=true&"  # became exclude_numbers
		#			 ."stopWords=&"
		#			 ."withDefaultStopWords=false&"
		#			 ."isStopWordsCaseSenstive=false&"
		#			 ."minTermSize=3&"      # became minimum_match_length
		#			 ."scored=true&"        # The scoring was removed.
		#			 ."withSynonyms=true&"  # By default include synonyms but I believe we do not have a flag to disable this at the moment. I have created a ticket to address this issue.
		#			 ."ontologiesToExpand=&"   # The ontologies param aligns with the old ontologiesToKeepInResult. To expand one needs to use the class endpoints.
		#			 ."ontologiesToKeepInResult=&" 
		#			 ."isVirtualOntologyId=true&"  #Suggest to set to true and use ontology virtual id 
		#			 ."semanticTypes=&" #T018,T023,T024,T025,T030&" 
		#			 ."levelMax=0&"
		#			 ."mappingTypes=&"  # null=do not expand mappings 
		#			 ."textToAnnotate=$text&"
		#			 ."format=$format&"  #);  #Possible values: xml, tabDelimited, text 
		#			 ."apikey=$API_KEY"); #Change to include your API Key - thanks!  
		."ontologies=EDAM,BAO,OBIWS,BRO,IAO,MS,MESH,OBI,SWO,NCIT,NIFSTD,EFO,SIO&"
		."text=$text&"
		."format=$format&"  # Possible values: xml, tabDelimited, text      
		."apikey=$API_KEY"); #Change to include your API Key - thanks!  


  # print("Req: ",$req->content,"\n");

  # send request and get response.
  my $resAnnot = $uaAnnot->request($req);
  my $parserAnnot = XML::LibXML->new();
  if ($resAnnot->is_success) {
      #print $resAnnot->decoded_content;  # this line prints out unparsed response 
      # Print URL of ontology terms
      print(">>> Ontology terms associated to this service description:\n");
      if ($format eq "xml") {
	  parse_annotator_response($resAnnot, $parserAnnot, $fileOut);
      } #end-if
  }else{
      print("BAD call: ".$resAnnot->content."\n");
      die $resAnnot->status_line;
  } # end if OpenBiomedicalAnnotator success call
} # end lookfor_ontology_terms subroutine


################################################################
# sub get_well_formed_biocatalogue_response
################################################################
sub get_well_formed_biocatalogue_response($$);
sub get_well_formed_biocatalogue_response($$){
  # Parameters
    my ($uaSub, $query) = @_;

    my $resp="";
    my $parser = XML::Parser->new();

    eval{
       $resp = $uaSub->get("$query");
       if ($resp->is_success){
	   $parser->parse($resp->content);
       }else{
	   print("BAD query ($query): ",$resp->status_line,"\n");
       } # end-if response=ok
    };
    if ($@) {
	print(">>> BAD FORMED!!!\n");
	$resp = get_well_formed_biocatalogue_response($uaSub,$query);
    } 

    return($resp);
}


################################################################
# sub obtain_description_WSDL
################################################################
sub obtain_description_WSDL($$){
  # Parameters
  my ($url, $operation) = @_;

  my $desc_sub="";

  # To include all the options by preference order, and to execute that working in each case. Objective: to obtain a description string as informative as we can.

  # Options for using the URL
  # 1.- GET URL --> Often it gives error.
  #   + filter in wsdl file: wsdl:definitions@name, wsdl:definitions/wsdl:documentation
  #   + filter operation:     wsdl:definitions/wsdl:portType/wsdl:operation[@name = $operation]/wsdl:documentation
  # 2.- GET https://www.biocatalogue.org/lookup.xml?wsdl_location="URL"
  #   + filter in soapFile: soapService/dc:description
  #   + filter in soapFile: soapService/operations/soapOperation/[name==operation]  and take soapService/operations/soapOperation/dc:description
  # 3.- GET https://www.biocatalogue.org/search.xml?q="URL"
  #   + filter in xml file: search/results/service/dc:description
  
  # Ex: wf1384: the four services have always the same URL. In two cases the same operation, and in the other two the operation is different. I should to include it in the text to search ontology terms associated with the whole set.
  my $ua = LWP::UserAgent->new;
  my $querySoap = "https://www.biocatalogue.org/lookup.xml?wsdl_location=$url";
  my $querySearch = "https://www.biocatalogue.org/search.xml?q=$url";
  my $parserServ;
  my $treeServ;
  my $rootServ;
  my $nameServ;
  my $descServ;
  my $descOper="";
  my $useSoap=0;
  my $useSearch=0;
  my $response;
  
  # 1.- Query=URL
   $response = $ua->get("$url");
   if ($response->is_success){
       print("OK: query=url\n");
       #		$parserServ = XML::LibXML->new(); $treeServ = $parserServ->parse_file("$url");
       $treeServ = XML::LibXML->load_xml(string => $response->content);
       $rootServ = $treeServ->getDocumentElement;
       #   + filter in wsdl file: wsdl:definitions@name, wsdl:definitions/wsdl:documentation
       #   + filter operation:     wsdl:definitions/wsdl:portType/wsdl:operation[@name = $operation]/wsdl:documentation
       if(($rootServ->getChildrenByTagName("documentation"))->size > 0){  # Without wsdl: prefix in some cases
	   $nameServ = $rootServ->findnodes('@name');
	   $descServ = ($rootServ->getChildrenByTagName("documentation"))->pop->textContent;
	   # $descOper = $rootServ->findnodes('portType/operation[@name="'.$operation.'"]/documentation/text()'); # It doesn't work
	   if( (($rootServ->getChildrenByTagName("portType"))->size) > 0){
	       my @operSets = (($rootServ->getChildrenByTagName("portType"))[0])->getChildrenByTagName("operation");
	       my $maxOper = scalar @operSets;
	       my $notFound = 0;
	       my $i=0;
	       while(($notFound == 0) && ($i < $maxOper)){
		   if(($operSets[$i]->findvalue('@name')) eq $operation){
		      $notFound=1;
		      if( (($operSets[$i]->getChildrenByTagName("documentation"))->size) > 0){
			  $descOper = ($operSets[$i]->getChildrenByTagName("documentation"))->pop->textContent;
		      }
		   } # end-if operation found
		   $i=$i+1;
	       } # end-while find operation
	   } #end-if operation>0
       }else{
	   print("WITH WSDL:\n");
	   $nameServ = $rootServ->findnodes('/wsdl:definitions/@name');
	   $descServ = $rootServ->findnodes('/wsdl:definitions/wsdl:documentation/text()');
	   $descOper = $rootServ->findnodes('/wsdl:definitions/wsdl:portType/wsdl:operation[@name="'.$operation.'"]/wsdl:documentation/text()');
       }
 
       $desc_sub=$descServ.". ".$operation.". ".$descOper;
       $desc_sub =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
       # print("### Whole description: $desc_sub\n");
       if($desc_sub eq ". . "){
 	  print("Empty description, to use next option: Soap\n");
 	  $useSoap=1;
       }
   }else{
       $useSoap=1;
       print("BAD query URL: ",$response->status_line,"\n");
   }


   if ($useSoap == 1){
       # 2.- Query=Soap (WSDL_location)
       $desc_sub="";
       $response = get_well_formed_biocatalogue_response($ua,$querySoap);
       if ($response ne ""){	   
 	  print("OK: query=lookup wsdl\n");
 	  $treeServ = XML::LibXML->load_xml(string => $response->content);
 	  $rootServ = $treeServ->getDocumentElement;	
 	  #   + filter in soapFile: soapService/dc:description
 	  #   + filter in soapFile: soapService/operations/soapOperation/[name==operation]  and take soapService/operations/soapOperation/dc:description
 	  # $nameServ = $rootServ->findnodes('/soapService/name/text()');
 	  $nameServ = $rootServ->getChildrenByTagName("name");
 	  # $descServ = $rootServ->findnodes('/soapService/dc:description/text()');
 	  $descServ = $rootServ->getChildrenByTagName("dc:description");
 	  # $descOper = $rootServ->findnodes('/soapService/operations/soapOperation[name="'.$operation.'"]/dc:description/text()'); # It doesn't work. I don't know why. I need a more complicated code.
	  if( (($rootServ->getChildrenByTagName("operations"))->size) > 0){
	      my @operSets = (($rootServ->getChildrenByTagName("operations"))[0])->getChildrenByTagName("soapOperation");
	      my $maxOper = scalar @operSets;
	      my $notFound = 0;
	      my $i=0;
	      while(($notFound == 0) && ($i < $maxOper)){
		  if(($operSets[$i]->findvalue('@resourceName')) eq $operation){
		      $notFound=1;
		      $descOper = $operSets[$i]->getChildrenByTagName("dc:description");
		  } # end-if operation found
 	      $i=$i+1;
	      } # end-while find operation
	  } #end-if operation>0
	  $desc_sub=$descServ.". ".$operation.". ".$descOper;
 	  $desc_sub =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
           # print("### Whole description: $desc_sub\n");
 	  if($desc_sub eq ". . "){
 	      print("Empty description, to use next option: Search\n");
	      $useSearch=1;
 	  } # end-if description	
       }else{
 	  $useSearch=1;
       }

       if($useSearch == 1){
	  # 3.- Query=Search
	  $desc_sub="";

	  $response = get_well_formed_biocatalogue_response($ua,$querySearch);
	  if ($response ne ""){
	      print("OK: query=Search\n");
	      # parserServ = XML::LibXML->new(); $treeServ = $parserServ->parse_file("$querySearch");
	      $treeServ = XML::LibXML->load_xml(string => $response->content);
	      $rootServ = $treeServ->getDocumentElement;
	      #   + filter in xml file: search/results/service/dc:description

	      # I assume only 1 service in the 'results' section, associated to the .wsdl uri !
	      $nameServ = (($rootServ->getChildrenByTagName("results"))[0]->getChildrenByTagName("service"))[0]->getChildrenByTagName("name");; # Whole path: /search/results/service/name
	      $descServ = (($rootServ->getChildrenByTagName("results"))[0]->getChildrenByTagName("service"))[0]->getChildrenByTagName("dc:description");; # Whole path: /search/results/service/dc:description
	      # I can't find any description about operation in this search. So, I include only the operation name.
	      $desc_sub=$descServ.". ".$operation;
	      $desc_sub =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
	      # print("### Whole description: $desc_sub\n");
	  }else{
	      $desc_sub="";
	  } # end-if response=ok
      } # end-if query=Search
  } # end-if useSoap

  return($desc_sub);
}


################################################################
# sub empty_desc
################################################################
sub empty_desc($){
    my ($desc) = @_;
    
    my $out=0;

    if(($desc eq "") || ($desc eq "[]")){
	$out=1;
    }
    return($out);
}


################################################################
# sub get_desc_by_urlBiocat
################################################################
sub get_desc_by_urlBiocat($){
  # Parameters
  my ($urlBiocat) = @_;

  my $desc_sub="";
  my $ua = LWP::UserAgent->new;
  my ($response, $treeServ, $rootServ);
  my $urlWSDL;

  print("Search by biocatalogue URL: $urlBiocat\n");
  $ua->show_progress(1);	  
  $response = $ua->get("$urlBiocat");
  if ($response->is_success){
      print("OK: query=Biocat url\n");
      $treeServ = XML::LibXML->load_xml(string => $response->content);
      $rootServ = $treeServ->getDocumentElement;
      # Take wsdlURL= service/variants/soapService/wsdlLocation
      $urlWSDL = (($rootServ->getChildrenByTagName("variants"))[0]->getChildrenByTagName("soapService"))[0]->getChildrenByTagName("wsdlLocation");
      print("wsdl URL: $urlWSDL\n");
      
      $response = $ua->get("$urlWSDL");
      if ($response->is_success){
	  print("OK: query=lookup wsdl\n");
	  $treeServ = XML::LibXML->load_xml(string => $response->content);
	  $rootServ = $treeServ->getDocumentElement;
	  # Take wsdl:definitions/wsdl:documentation/text() (if it's available)
	  $desc_sub = $rootServ->findnodes('/wsdl:definitions/wsdl:documentation/text()');
      }else{
	  print("BAD query Search Biocatalogue ($urlWSDL): ",$response->status_line,"\n");
	  $desc_sub="";
      } # end-if response=ok
  }else{
      print("BAD query Search Biocatalogue ($urlBiocat): ",$response->status_line,"\n");
      $desc_sub="";
  } # end-if response=ok

  return($desc_sub);
} # end-sub get_desc_by_urlBiocat


################################################################
# sub get_desc_by_serviceNode
################################################################
sub get_desc_by_serviceNode($){
  # Parameters
  my ($service) = @_;

  my $desc_sub="";
  my $urlBiocat="";

  $desc_sub = $service->getChildrenByTagName("dc:description");
  $urlBiocat = $service->getAttribute("xlink:href");
  if(($urlBiocat ne "") && (empty_desc($desc_sub))){
      $desc_sub = get_desc_by_urlBiocat($urlBiocat.".xml");
  } # end-if urlBiocat search
			    
  return($desc_sub);
} # end-sub get_desc_by_serviceNode


################################################################
# sub get_desc_by_1orMoreServices
################################################################
sub get_desc_by_1orMoreServices($$+){
    # Parameters
    my $nameServ = $_[0];
    my $maxServ =  $_[1];
    my @servList = @{$_[2]}; 

    my $descServ="";  
    my $found;
    my $i;

    if($maxServ == 1){
	$descServ = get_desc_by_serviceNode($servList[0]);
    }else{
	# To select the service whit @resourceName=nameServ
	$found = 0;
	$i=0;
	while(($found == 0) && ($i < $maxServ)){
	    if(($servList[$i]->findvalue('@resourceName')) eq $nameServ){
		$found=1;
		$descServ = get_desc_by_serviceNode($servList[$i]);
	    } # end-if service found
	    $i=$i+1;
	} # end-while 		  		 
	
	# To select that service which contains nameServ in @resourceName
	# If not description yet, independently on there is $urlBiocat or not.
	if(empty_desc($descServ)){
	    $i=0;
	    while((empty_desc($descServ)) && ($i < $maxServ)){
		if((index(($servList[$i]->getAttribute("resourceName")),$nameServ)) > -1){
		    $descServ = get_desc_by_serviceNode($servList[$i]);    
		} # end-if service found
		$i=$i+1;
	    } # end-while service found
	} # end-if not service with @resourceName=nameServ or description not found!
	
#                 LOOK OUT! I have commented this fragment because I have checked the search by "nameServ" could give many services and, apparently, all of them are not related with the given soap service!!!!!!!
# 		  # If there aren't any service with nameServ IN @resourceName, or description is empty. To take whatever description of a service searched by "$nameServ"
# 		  if(empty_desc($descServ)){
# 		      $i=0;
# 		      while((empty_desc($descServ)) && ($i < $maxServ)){
#   		          $descServ = get_desc_by_serviceNode($servList[$i]);    
# 			  $i=$i+1;
# 		      } # end-while service found
# 		  } # end-if service without description
    } # end-else if maxServices > 1

  return($descServ);
}

################################################################
# sub obtain_description_SOAP
################################################################
sub obtain_description_SOAP($$){
  # Parameters
  my ($url, $nameServ) = @_;

  my $desc_sub="";

  # To include all the options by preference order, and to execute that working in each case. Objective: to obtain a description string as informative as we can.

  # GET https://www.biocatalogue.org/search.xml?q="URL"
  #   + take in xml file: search/results/service/@resourceName
  #   + take in xml file: search/results/service/dc:description
  #   + take in xml file: $urlBiocat=search/results/service@xlink:ref
  
  my $ua = LWP::UserAgent->new;
  my $querySearch;
  my $parserServ;
  my $treeServ;
  my $rootServ;
  my $nodeServ;
  my $descServ="";
  my $descOper;
  my $useSoap=0;
  my $useSearch=0;
  my $response;
  my @servList;
  my $urlBiocat="";
  my $maxServ;

  my $queryByName=0;
  
  #print("URL in description_SOAP: $url\n");
  #print("nameServ: ".$nameServ."\n");

  $ua->show_progress(1);

  # 1.- Query by URI
  # I look for the whole URI and if there isn't results, then I look for by nameServ. Because in deprecated endPoint URIs doesn't return any description, but $nameServ yes. Although the search in Biocatalogue with nameServ is longer (and more frequently bad formed) than with URI.
  $querySearch = "https://www.biocatalogue.org/search.xml?q=$url"; 
  $response = get_well_formed_biocatalogue_response($ua,$querySearch);
  if($response ne ""){
      $treeServ = XML::LibXML->load_xml(string => $response->content);
      $rootServ = $treeServ->getDocumentElement;

      @servList = ($rootServ->getChildrenByTagName("results"))[0]->getChildrenByTagName("service");
      $maxServ = scalar @servList;
      if($maxServ == 0){
	  $queryByName=1;
      }else{
	  $descServ = get_desc_by_1orMoreServices($nameServ,$maxServ,@servList);
	  if(empty_desc($descServ)){
	      $queryByName=1;
	  } # end-if not description.
      } # else if $maxService > 0     
  }else{  # if response == ""
      $queryByName=1;
  }
  
  # 2.- Query by name
  if(($queryByName == 1) || (empty_desc($descServ)) ){
      $querySearch = "https://www.biocatalogue.org/search.xml?q=$nameServ"; 
      $response = get_well_formed_biocatalogue_response($ua,$querySearch);
      if($response ne ""){
	  $treeServ = XML::LibXML->load_xml(string => $response->content);
	  $rootServ = $treeServ->getDocumentElement;

	  @servList = ($rootServ->getChildrenByTagName("results"))[0]->getChildrenByTagName("service");
	  $maxServ = scalar @servList;
	  if($maxServ == 0){
	      print("Description not found!\n");
	  }else{
	      $descServ = get_desc_by_1orMoreServices($nameServ,$maxServ,@servList);
	      if(empty_desc($descServ)){
		  print("Description not found!\n");
	      } # end-if not description.
	  } # else if $maxService > 0	  
      }  # end-if response == ""
  } # end-if query by name
      
  # I can't find any description about operation in SOAPlab services. So, only service description.
  $desc_sub=$descServ;
  $desc_sub =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
  $desc_sub =~ s/\[\]//; # Replace 2 or more blanks, tab or new lines with a single blank.
  
  print("### Whole description subroutine SOAP: $desc_sub\n");
      
  return($desc_sub);
}


################################################################
# sub obtain_description_REST
################################################################
sub obtain_description_REST($$){
  # Parameters
  my ($url, $nameServ) = @_;

  my $desc_sub="";

  # To retrieve a small URL, until the first ? or { (where the parameters begin).
  my $urlRest;
  if(index($url,"?") > -1){
      $urlRest=(split("\\?",$url))[0];
  }elsif(index($url,"{") > -1){
      $urlRest=(split("\\{",$url))[0];
  }else{
      $urlRest=$url;
  }
  print("urlRest: $urlRest\n");
  
  $desc_sub=obtain_description_SOAP($urlRest,$nameServ);

  return($desc_sub);
}


################################################################
# sub obtain_description_MOBY
################################################################
sub obtain_description_MOBY($){
  # Parameters
  my ($nameServ) = @_;

  my $bioMobyDescURL = "http://moby.ucalgary.ca/cgi-bin/getServiceDescription";
  my $parser = XML::LibXML->new(recover => 2);

  my $desc_sub="";
  my $href="";
  my ($doc, $root, $service);
  my @line;
 
  
  print("nameServ: ".$nameServ."\n");


  $doc = $parser->load_html(location => $bioMobyDescURL);
  $root = XML::LibXML::XPathContext->new($doc);
  $service = ($root->findnodes('/descendant::a[contains(@href,'."'$nameServ'".')]'))[0];
  print("service: ".$service->textContent."\n");
  $href=$service->findvalue('@href');
  
  $doc = $parser->load_html(location => $href);

  @line = split('<br>|<br \/>|<br\/>',$doc->toString);
  $desc_sub = (grep(/<b>Description:<\/b>/,@line))[0]; # [0]: There is only 1 element <b>Desc...</b>
  $desc_sub =~ s/<b>Description:<\/b>//;

  $desc_sub =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
  $desc_sub =~ s/\[\]//; # Replace 2 or more blanks, tab or new lines with a single blank.
     
  print("### Whole description subroutine MOBY: $desc_sub\n");
  
  return($desc_sub);
}


################################################################
# sub obtain_URL_MOBY
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
      print("service: ".$service->textContent."\n");
      $href=$service->findvalue('@href');
      
      $doc = $parser->load_html(location => $href);

      @line = split('<br>|<br \/>|<br\/>',$doc->toString);
      $url_sub = (grep(/<b>Endpoint:<\/b>/,@line))[0]; # [0]: There is only 1 element <b>Endpoint</b>
      $url_sub =~ s/<b>Endpoint:<\/b>//;
  }
  
  return($url_sub);
}



###########################################################################
#
############################## MAIN PROGRAM ###############################
#
###########################################################################

my ($servName, $nameServ);
my $servType="";
my $url="";
my $operation="";
my $description="";
my $desc_subroutine="";

unlink($fileOut);

my $parser = XML::LibXML->new();
$parser->keep_blanks(0); # To avoid blank lines from the removed nodes
my $doc = $parser->parse_file($fileIn); # Return XML::LibXML::Document

my $wfId=(split("\_withoutShims",(split("wf_myExperiment_",basename($fileIn)))[1]))[0];

my @line=split("\\.",$fileIn);
my $type=$line[$#line]; # Take last element in the array, that is the extension (.xml or .t2flow).

my $idNestedWf;

if($type eq "xml"){ # SCUFL format (Taverna 1)
    print("SCUFL format\n");

    my $root = $doc->getDocumentElement; # Return XML::LibXML::Node

    my $wsdlNode;
    my $count=1;
    foreach my $service ($root->findnodes('/descendant::s:processor')){
	$url="";
	$operation="";
	$description="";
	$desc_subroutine="";

	print("\nSERVICE $count-------------------\n");
	$servName = $service->getAttribute("name");
	print("service name: $servName\n");

	if ($service->exists('s:description')){
	    $description = ($service->getChildrenByTagName("s:description"))[0]->textContent;
	    $description =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
	    print("Description SCUFL: $description\n");
	}
	if ($service->exists('s:arbitrarywsdl')){
	    $servType='wsdl';
	    print("service type: $servType\n");

	    $wsdlNode = ($service->getChildrenByTagName("s:arbitrarywsdl"))[0];
	    $url=($wsdlNode->getChildrenByTagName("s:wsdl"))[0]->textContent;
	    $operation=($wsdlNode->getChildrenByTagName("s:operation"))[0]->textContent;
	    print("URI [operation]: $url [$operation]\n");

	    $desc_subroutine=obtain_description_WSDL($url,$operation);
	}elsif($service->exists('s:biomart')){
	    $servType='BioMart';
	    print("service type: BioMart\n");
	    $url="http://www.biomart.org/biomart/martservice";
	}elsif(($service->exists('s:biomobyparser')) || ($service->exists('s:biomobyobject')) || ($service->exists('s:biomobywsdl'))){
	    $servType='BioMoby';
	    print("service type: BioMoby\n");
	    # There are several endpoints (<s:biomobyparser>/<s:endpoint>, s:biomobyobject><s:mobyEndpoint)>
	    # Available description is already got from s:description + @name. No more text available, because the description in 'http://moby.ucalgary.ca/cgi-bin/getServiceDescription' (used in t2flow) is the same that in the scufl file.
	    $desc_subroutine="";
	    $url=obtain_URL_MOBY($servName);
	    if($url eq ""){
		if($service->exists('s:biomobyparser')){
		    $url = ($service->getElementsByTagName("s:endpoint"))[0]->textContent;
		}elsif(($service->exists('s:biomobyobject')) || ($service->exists('s:biomobywsdl'))){
		    $url = ($service->getElementsByTagName("s:mobyEndpoint"))[0]->textContent;
		}
	    } #end-if URL==""
	}elsif($service->exists('s:soaplabwsdl')){
	    $servType='Soap';
	    print("service type: Soap\n");
            # URL=s:scufl/s:processor/s:soaplabwsdl
	    $url = ($service->getChildrenByTagName("s:soaplabwsdl"))[0]->textContent;
	    $desc_subroutine=obtain_description_SOAP($url,$servName);
	}elsif($service->exists('s:rshell')){
	    $servType='Rshell';
	    print("service type: Rshell\n");
	}elsif($service->exists('s:workflow')){
	    $servType='workflow';	 
	    print("service type: nested workflow\n");
	    $idNestedWf = ($service->getElementsByTagName("s:workflowdescription"))[0]->getAttribute("lsid");
	    $url="http://www.myexperiment.org/workflows/$wfId/$idNestedWf";
	} # end-if case service type
	$description = $servName.": ".$description.". ".$desc_subroutine;
	$description =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
	# print("### Whole description with SCUFL: ".$description."\n");
	     
	# Print in output file service information (yet or not with ontology annotations)
	open(Fout,">>$fileOut") or die "Couldn't open: $fileOut";
	print(Fout "\n-----------------------------------------------------------------------------\n");
	print(Fout "service name: $servName\n");	
	print(Fout "service type: $servType\n");
	print(Fout "URI: $url");	
	if($operation ne ""){ print(Fout " [$operation]\n"); }else{ print(Fout "\n");}
	print(Fout "Description: $description\n");
	close(Fout);

	# Look for ontology term with OpenBiomedicalAnnotator, using $description variable, which could have been filled in whatever previous step.
	# Fragments of code (with my modifications) from: https://bmir-gforge.stanford.edu/gf/project/client_examples/scmsvn/?action=browse&path=%2F*checkout*%2Ftrunk%2FPerl%2FAnnotator-Perl%2Fannotator.pl&revision=49]
	if($description ne ""){
	    lookfor_ontology_terms($description, $fileOut);
	}else{
	    print("ontolgoy terms can't be associated to a service with empty description!!!\n");
	} # end-if empty description 
	$count=$count+1;
    } # end-foreach services


}elsif($type eq "t2flow"){ # T2FLOW format (Taverna 2)
    print("T2FLOW format\n");

    my $root = XML::LibXML::XPathContext->new($doc);
    $root->registerNs('ns','http://taverna.sf.net/2008/xml/t2flow');

    my ($class, $parent, $headerClass);
    my $count=1;
    foreach my $service ($root->findnodes('//ns:workflow/ns:dataflow/ns:processors/ns:processor')){
	$url="";
	$operation="";
	$description="";
	$desc_subroutine="";

	print("\nSERVICE $count-------------------\n");
	$servName = (($service->getChildrenByTagName("name"))[0])->textContent;
	print("service name: $servName\n");	

	$class = (($service->getElementsByTagName("class"))[0]); # Whole path: ns:activities/ns:activity/ns:class
	$servType=$class->textContent;
	$headerClass="net.sf.taverna.t2.activities.";
	$servType =~ s/$headerClass//;
	print("service type: $servType\n");

	$description=""; # It is used later for looking for ontology terms with OpenBiomedicalAnnotator

	if($servType eq "wsdl.WSDLActivity") {
	    # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
	    $parent=$class->parentNode;
	    $url= (($parent->getElementsByTagName("wsdl"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.wsdl.WSDLActivityConfigurationBean/wsdl
	    $operation=(($parent->getElementsByTagName("operation"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.wsdl.WSDLActivityConfigurationBean/operation
	    print("URI [operation]: $url [$operation]\n");
	    $desc_subroutine=obtain_description_WSDL($url,$operation);
	}elsif(index($servType,"biomart") > -1){
	    # biomart.BiomartActivity
	    $url="http://www.biomart.org/biomart/martservice";
	    print("In if BioMart\n");
	    ########### TO-DO
	}elsif(index($servType,"biomoby.BiomobyActivity") > -1){	
	    # biomoby.BiomobyActivity  <-- We only have annotations for these ones, neither for Object nor for DatatypeActivity (biomoby.BiomobyObjectActivity, biomoby.MobyParseDatatypeActivity).
	    # To search description in 'http://moby.ucalgary.ca/cgi-bin/getServiceDescription'
	    $desc_subroutine=obtain_description_MOBY($servName);
	    $url=obtain_URL_MOBY($servName);
	}elsif(index($servType,"soaplab") > -1){
	    # soaplab.SoaplabActivity
	    # CHECK WITH service no.5 in output_16.t2flow and wf_myExperiment_2226_withoutShims.t2flow (many soap services!)
	    # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
	    $parent=$class->parentNode;
	    # URL=processor/activities/configBean/
	    $url= (($parent->getElementsByTagName("endpoint"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.soaplab.SoaplabActivityConfigurationBean/endPoint
	    print("URI: $url\n");
	    $desc_subroutine=obtain_description_SOAP($url,$servName);
	}elsif(index($servType,"rshell") > -1){
	    # rshell.RshellActivity
	    print("In if Rshell\n");
	    ########### TO-DO
	}elsif(index($servType,"rest.RESTActivity") > -1){
	    # rest.RESTActivity
	    print("In if REST\n");
	    # CHECK WITH wf_myExperiment_1510_withoutShims.t2flow
	    # parent=//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/
	    $parent=$class->parentNode;
	    # URL=processor/activities/configBean/
	    $url= (($parent->getElementsByTagName("urlSignature"))[0])->textContent; # Whole path: configBean/net.sf.taverna.t2.activities.rest.RESTActivityConfigurationBean/urlSignature
	    print("URI: $url\n");
	    $desc_subroutine=obtain_description_REST($url,$servName);
	}elsif($servType eq "dataflow.DataflowActivity") {
	    $parent=$class->parentNode;
	    $idNestedWf=((($parent->getElementsByTagName("configBean"))[0])->getChildrenByTagName("dataflow"))[0]->getAttribute("ref");
	    $url="http://www.myexperiment.org/workflows/$wfId/$idNestedWf";
#	    $desc_subroutine=$root->findvalue('//ns:workflow/ns:dataflow[@id="'.$url.'"]/ns:annotations/ns:annotation_chain[@encoding="xstream"]/ns:net.sf.taverna.t2.annotation.AnnotationChainImpl/ns:annotationAssertions/ns:net.sf.taverna.t2.annotation.AnnotationAssertionImpl/ns:annotationBean[@class="net.sf.taverna.t2.annotation.annotationbeans.FreeTextDescription"]/ns:text'); # It doesn't work
	    my $elem;
 	    foreach my $annot ($root->findnodes('//ns:workflow/ns:dataflow[@id="'.$idNestedWf.'"]/ns:annotations/ns:annotation_chain[@encoding="xstream"]')){		
		$elem=($annot->getElementsByTagName('annotationBean'))[0];
		if(($elem->getAttribute('class')) eq 'net.sf.taverna.t2.annotation.annotationbeans.FreeTextDescription'){
		    $desc_subroutine=$elem->getChildrenByTagName('text');
		} # end-if
 	    } # end-foreach
	}else{
	    print("Type of service not recognized!\n");
	    ### What can I do with dataflow services???
	}
	$description = $servName.": ".$desc_subroutine; # $desc_subroutine includes operation name and operation description.
	$description =~ s/[ \t\n]{2,}/ /g; # Replace 2 or more blanks, tab or new lines with a single blank.
	$description =~ s/[\n]/ /g; # Replace a new line with a single blank.

	# Print in output file service information (yer or not with ontology annotations)	
	open(Fout,">>$fileOut") or die "Couldn't open: $fileOut";
	print(Fout "\n-----------------------------------------------------------------------------\n");
	print(Fout "service name: $servName\n");	
	print(Fout "service type: $servType\n");	
	print(Fout "URI: $url");	
	if($operation ne ""){ print(Fout " [$operation]\n"); }else{ print(Fout "\n");}
	print(Fout "### description: $description\n");
	close(Fout);

	# Look for ontology terms with OpenBiomedicalAnnotator, using $description variable, which could have been filled in whatever previous step.
	# Fragments of code (with my modifications) from: https://bmir-gforge.stanford.edu/gf/project/client_examples/scmsvn/?action=browse&path=%2F*checkout*%2Ftrunk%2FPerl%2FAnnotator-Perl%2Fannotator.pl&revision=49]
	if($description ne ""){
	    lookfor_ontology_terms($description, $fileOut);
	}else{
	    print("Ontology terms can't be associated to a service with empty description!!!\n");
	} # end-if empty description 

	# Increase the count of services
	$count=$count+1;
    } # end-foreach services
}else{
    print("ERROR: The file extension must be .xml for Taverna 1 workflows or .t2flow for Taverna 2 workflows!!!\n");
} # end-if SCUFL/T2FLOW format


