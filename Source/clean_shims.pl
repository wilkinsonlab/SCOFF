# Call: perl clean shims.pl <Input-workflowFile.xml or .t2flow> <Output-workflowFile>
# Example: perl clean_shims.pl ../Data/WF_myExperiment/wf_myExperiment_16.t2flow output.t2flow.xml

# Description:  (SCUFL format for Taverna 1 and T2FLOW for Taverna2), only for Taverna 1 and Taverna 2 workflows.

# Categories of services considered as shims: XML_Splitter, Spreadsheet Import, String/Text constant, Beanshell, Local services, Xpath

# 1.- To distinguish if .xml or .t2flow file.
# 2.- To read xml file, with XML::LibXML.
# 3.- To look for each processor in xml file, and if the service type is some shim (those are:  XML_Splitter, Spreadsheet Import, String/Text constant, Beanshell, Local services, Xpath), then to remove all the processor label content in the output file.
# When the previous tasks work: to convert to a function and to write a loop for all the workflow files.

use XML::LibXML;

my $fileIn=@ARGV[0];
my $fileOut=@ARGV[1];

my $parser = XML::LibXML->new();
$parser->keep_blanks(0); # To avoid blank lines from the removed nodes
my $doc = $parser->parse_file($fileIn); # Return XML::LibXML::Document

@line=split("\\.",$fileIn);
$type=$line[$#line]; # Take last element in the array, that is the extension (.xml or .t2flow).
if($type eq "xml"){ # SCUFL format (Taverna 1)
    print("SCUFL format\n");

    my $root = $doc->getDocumentElement; # Return XML::LibXML::Node
    
    # To define parent node from the processor nodes must be removed.
#    @serviceNodes = $root->findnodes('/s:scufl/s:processor'); # It only selects processor in the root, not nested in other workflow.
    @serviceNodes = $root->findnodes('/descendant::s:processor');
    # Loop over all child nodes, because the shim definition tag could not be the first one.
    foreach $service (@serviceNodes){
	$isRemoved = 0;
	@childNodes = $service->childNodes();	
	foreach $child (@childNodes){
	    $servType = $child->nodeName; 

	    # To filter whether it is shim service:
               # "s:local" ==> XML Splitters, local services, XPath_Service
	       # "s:stringconstant" ==> String/Text constant
	       # Spreadsheet Import: They are not defined in SCUFL format.
	       # "s:beanshell" ==> # Beanshell
	       # "s:scriptvalue" ==> # Beanshell

	       # PENDING!!!!!: TO DECIDE IF ONLY SOME type of local services should be removed, such as:
	       # XML Splitters:   <s:local> org.embl.ebi.escience.scuflworkers.java.XMLInputSplitter
	       #               or <s:local> org.embl.ebi.escience.scuflworkers.java.XMLOutputSplitter
	       # Local services: <s:local>org.embl.ebi.escience.scuflworkers.java.FilterStringList (Java class example)
	       # XPath service: <s:local>net.sourceforge.taverna.scuflworkers.xml.XPathTextWorker
	    if(($servType eq "s:local") || ($servType eq "s:stringconstant") || ($servType eq "s:beanshell") || ($servType eq "s:scriptvalue"))
	   { 
	       # Shim service identified that must be removed.
	       if($isRemoved == 0){
		   # PROCESSOR
		   # Name of the service:
		   $servName = $service->findvalue('@name');
		   print("-->Service removed: ",$servName," [$servType]\n");
		   $parent = $service->parentNode;
		   $parent->removeChild($service);
		   $isRemoved=1;		   

		   # LINKS
		   # Remove input and output ports associated to this service.
		   # $queryXPathSink='/s:scufl/s:link[contains(@sink,"'.$servName.':")]'; # It doesn't include input/outputs in nested workflows.
		   # $queryXPathSource='/s:scufl/s:link[contains(@source,"'.$servName.':")]';  # It doesn't include input/outputs in nested workflows.
		   $queryXPathSink='/descendant::s:link[contains(@sink,"'.$servName.':")]';
		   $queryXPathSource='/descendant::s:link[contains(@source,"'.$servName.':")]';
		   @datalinkSinkList = $root->findnodes($queryXPathSink);
		   @datalinkSourceList = $root->findnodes($queryXPathSource);
		   if(scalar @datalinkSinkList == 0){		    
		       print("WITHOUT INPUTS.\n");
		       foreach $datalinkSource (@datalinkSourceList){
			   print("Output removed.\n");
#			   print("### SOURCE -->  SINK: ",$datalinkSource->findvalue('@source'),"--->",$datalinkSource->findvalue('@sink'),"\n");
			   $parent = $datalinkSource->parentNode;
			   $parent->removeChild($datalinkSource);
		       } # end-foreach service datalink Source (service outputs)
		   }else{
		       # The service YES has inputs.
		       foreach $datalinkSink (@datalinkSinkList){
			   foreach $datalinkSource (@datalinkSourceList){
			       # a.-Get a copy of the complete datalink node
			       $cloneDatalinks = $datalinkSink->cloneNode(1);
#
#			       print("### cloneDatalink SOURCE--->SINK: ",$cloneDatalinks->findvalue('@source'),"--->",$cloneDatalinks->findvalue('@sink'),"\n");
#			
			       # b.-Modify the value of the sink attribute in the link with sink=<our removed service>
			       $cloneDatalinks->setAttribute('sink',$datalinkSource->findvalue('@sink'));
			       # c.-Update Links with the new node:
#			       $parent = $datalinkSink->parentNode;
			       $parent->appendChild($cloneDatalinks);
			       # print("### cloneDatalink ADDED (Source-->Sink): ",$cloneDatalinks->findvalue('@source'),"--->",$cloneDatalinks->findvalue('@sink'),"\n");
			   } # end-foreach service datalink Source (service outputs)
		       } # end-foreach service datalink Sink (service inputs)

		       # To remove old datalink, in next two loops, with processor=<removed shim>
		       @datalinkSinkList = $root->findnodes($queryXPathSink);
		       foreach $datalinkSink (@datalinkSinkList){
			   print("Input removed.\n");
#			   print("### SOURCE ---> SINK: ",$datalinkSink->findvalue('@source'),"--->",$datalinkSink->findvalue('@sink'),"\n");
			   $parent = $datalinkSink->parentNode;
			   $parent->removeChild($datalinkSink);
		       } # end-foreach service datalink Sink (service inputs)		
		       @datalinkSourceList = $root->findnodes($queryXPathSource);
		       foreach $datalinkSource (@datalinkSourceList){
			   print("Output removed.\n");
#			   print("### SOURCE ---> SINK: ",$datalinkSource->findvalue('@source'),"--->",$datalinkSource->findvalue('@sink'),"\n");
			   $parent = $datalinkSource->parentNode;
			   $parent->removeChild($datalinkSource);
		       } # end-foreach service datalink Source (service outputs)
		   } # end-if service without inputs.

		   # CONDITIONS
		   # To propagate associated conditions
		   $queryXPathConditionOut='/descendant::s:coordination[s:action/s:target[contains(.,"'.$servName.'")]]';
		   $queryXPathConditionIn='/descendant::s:coordination[s:condition/s:target[contains(.,"'.$servName.'")]]';
		   @conditionOutList = $root->findnodes($queryXPathConditionOut);
		   foreach $outCondition (@conditionOutList){		   
#		       print("### OutCondition: ",$outCondition->textContent,"\n");
		       @conditionInList = $root->findnodes($queryXPathConditionIn);
		       foreach $inCondition (@conditionInList){
#			   print("### InCondition: ",$inCondition->textContent,"\n");
			   # a.-Get a copy of the complete control condition node
			   $cloneCondition = $inCondition->cloneNode(1);
			   # b.-Modify target service of the condition
			   # And Should I put the rest of parameter with the same copied values? I have checked that I can't remove them, although when the workflow is saved as .t2flow they are not preserved. I will inherite the conditions from input to previous inputs. I will only change the name for avoiding duplicates (target_BLOCKON_action). It isn't enough different, because it could have different pairs of conditions related to the same input and output services.
			   $newName=($outCondition->findvalue('s:condition/s:target'))."_BLOCKON_".($outCondition->findvalue('s:action/s:target'));
#			   print("### newName=",$newName,"\n");
			   $cloneCondition->setAttribute("name",$newName);
                           ####	$cloneCondition->condition->target=outCondition->coordination/action/target;
			   # cloneCondition->coordination/condition/target=outCondition->coordination/action/target;
			   $cloneCondition->setAttribute("control",$outCondition->getAttribute("control"));
			   # c.-Update Conditions with the new condition (at the end, old condition associated with the removed server would be deleted).
#			   $parent=($controlCondition->parentNode);
#			   $parent->appendChild($cloneCondition);
#			   print("### New condition: ",$cloneCondition->textContent,"\n");
		       } # end-foreach condition where CONTROL is current removed service
		   } # end-foreach condition where TARGET is current removed service
		   
		   # To remove old conditions, in next two loops, with target or control=<removed shim>
		   @conditionOutList = $root->findnodes($queryXPathConditionOut);
		   foreach $outCondition (@conditionOutList){
#		       print("### Condition removed (control-->target) ",$outCondition->getAttribute("control"),"-->",$outCondition->getAttribute("target"),"\n");
		       $parent=($outCondition->parentNode);
		       $parent->removeChild($outCondition);		
		   } # end-foreach condition where TARGET is current removed service
		   @conditionInList = $root->findnodes($queryXPathConditionIn);
		   foreach $inCondition (@conditionInList){
#		       print("##Condition removed (control-->target) ",$inCondition->getAttribute("control"),"-->",$inCondition->getAttribute("target"),"\n");
		       $parent=($inCondition->parentNode);
		       $parent->removeChild($inCondition);
		   } # end-foreach condition where CONTROL is current removed service
		   # end-CONDITION block

	       } # end-if is not Removed
	   } # end-if shim service
	} # end-foreach service childs
    } # end-foreach services

#    foreach my $tagID ($root->findnodes('/s:scufl/s:processor/@name')){
#	print("ProcName: ",$tagID->to_literal,"\n");
#    } # It prints all values of each element 'tag' in the individual element 'tags'.

#    $xmlFragment=$root->findnodes('/s:scufl/s:processor');
#    print("Fragment: $xmlFragment\n");

#XML::LibXML::Document [http://search.cpan.org/~shlomif/XML-LibXML-2.0107/lib/XML/LibXML/Document.pod]
#$state = $doc->toFile($filename, $format);

# IMPORTANT!!!!!! XML::LibXML::Node [http://search.cpan.org/~shlomif/XML-LibXML-2.0107/lib/XML/LibXML/Node.pod]
#$childnode = $node->removeChild( $childnode );
# I must get the "processor" node in an independent variable ($childnode) and its parent ($node), and I hope the node be removed from the complete $doc XML::LibXML::Document.
# The node to remove must be in an independent variable ($childnode) and its parent ($node) in other one, and then the $childnode is removed from the complete $doc XML::LibXML::Document.

    # TO SEE http://www.xml.com/pub/a/2001/11/14/xml-libxml.html TO FINISH!!!!!!!!
#    my @services = $root->getElementsByTagName('/s:scufl/s:processor');
#    foreach my $serv (@services){
#	my $procName = $serv->getAttribute('name');
#	print("ProcName=$procName->toString\n");
#    }

# To look for a nest tag (only could have one of them, or another different from these. Only in the next level, because it could have this kind of services inside a <s:workflow> tag).
# XML_Splitter: s:local
# Spreadsheet Import: ----
# String/Text constant: s:stringconstant
# Beanshell: s:beanshell, s:scriptvalue
# Local services: 
# Xpath: s:local>net.sourceforge.taverna.scuflworkers.xml.XPathTextWorker

}elsif($type eq "t2flow"){ # T2FLOW format (Taverna 2)
    print("T2FLOW format\n");

    # IMP: The same t2flow could have several dataflow tags (from nested workflows)!!! This code remove shims from all dataflows

    my $root = XML::LibXML::XPathContext->new($doc);
    $root->registerNs('ns','http://taverna.sf.net/2008/xml/t2flow');

    # To define parent node from the processor nodes must be removed.
    # It also works, although not neccesary, because $parent is recomputed below. Even below is better due to this does not work for several 'dataflows'.
    # $parent = ($root->findnodes('//ns:workflow/ns:dataflow/ns:processors'))[0]; 

    # It doesn't work. Several attempts:
    #    @serviceNodes = $root->findnodes('//ns:workflow/ns:dataflow/ns:processors/ns:processor');
    #    @serviceNodes = $parent->childNodes();
    #	$service->setNamespace("http://taverna.sf.net/2008/xml/t2flow");
    #	@classes=$root->findnodes('ns:activities/ns:activity/ns:class',$service);
    $count=1;
    foreach $class ($root->findnodes('//ns:workflow/ns:dataflow/ns:processors/ns:processor/ns:activities/ns:activity/ns:class')){
	print("SERVICE $count-------------------\n");
	$servType=$class->textContent;
	$headerClass="net.sf.taverna.t2.activities.";
	$servType =~ s/$headerClass//;

	if(($servType eq "wsdl.xmlsplitter.XMLInputSplitterActivity") || ($servType eq "wsdl.xmlsplitter.XMLOutputSplitterActivity") || ($servType eq "Spreadsheet.SpreadsheetImportActivity") || ($servType eq "stringconstant.StringConstantActivity") || ($servType eq "beanshell.BeanshellActivity") || ($servType eq "localworker.LocalworkerActivity") || ($servType eq "xpath.XPathActivity"))	
	{ 
	    # PROCESSOR
	    # Shim service identified that must be removed.
	    $service = (($class->parentNode)->parentNode)->parentNode;
	    # Parent of the service, needed for removing it.
	    $parent = $service->parentNode;

	    # Name of the service:
	    $servName = (($service->getChildrenByTagName("name"))[0])->textContent;
	    print("-->Service removed: $servName [$servType]\n");
	    
	    # Remove service node
	    $parent->removeChild($service);

	    # DATALINKS
	    # Remove input and output ports associated to this service.
	    $queryXPathSink='//ns:workflow/ns:dataflow/ns:datalinks/ns:datalink[ns:sink/ns:processor = "'.$servName.'"]';
	    $queryXPathSource='//ns:workflow/ns:dataflow/ns:datalinks/ns:datalink[ns:source/ns:processor = "'.$servName.'"]';
	    @datalinkSinkList = $root->findnodes($queryXPathSink);
	    @datalinkSourceList = $root->findnodes($queryXPathSource);
	    if(scalar @datalinkSinkList == 0){
		print("WITHOUT INPUTS.\n");
		foreach $datalinkSource (@datalinkSourceList){
		    print("Output removed.\n");
#		    print("### SOURCE: ",(($datalinkSource->getChildrenByTagName("source"))[0])->textContent,"\n");
#		    print("### SINK: ",(($datalinkSource->getChildrenByTagName("sink"))[0])->textContent,"\n");
		    $parentDatalinks=($datalinkSource->parentNode);
		    $parentDatalinks->removeChild($datalinkSource);
		} # end-foreach service datalink Source (service outputs)
	    }else{
		foreach $datalinkSink (@datalinkSinkList){
		    $parentDatalinks=(($datalinkSinkList[0])->parentNode);
		    foreach $datalinkSource (@datalinkSourceList){
			# a.-Get a copy of the complete datalink node
			$cloneDatalinks = $datalinkSink->cloneNode(1);
#
#			print("### cloneDatalinksSOURCE: ",(($cloneDatalinks->getChildrenByTagName("source"))[0])->textContent,"\n");
#			print("### cloneDatalinksSINK: ",(($cloneDatalinks->getChildrenByTagName("sink"))[0])->textContent,"\n");
#			
			# b.-Get a copy of one child from the datalinkSource node (the sink node).
			# Because I can't modify directly the content of the tag values, with something like: "$clone->sink->processor = $datalinkSource->sink->processor"; and "$clone->sink->port = $datalinkSource->sink->port;"
			$oldSinkNode=($datalinkSink->getChildrenByTagName("sink"))[0];
#
#			print("### oldSinkNode: ",$oldSinkNode->textContent,"\n");
#
			$newSinkNode=($datalinkSource->getChildrenByTagName("sink"))[0]->cloneNode(1);
#
#			print("### newSinkNode: ",$newSinkNode->textContent,"\n");
#
			# c.-Replace the "sink" node in the new datalink node
			$cloneDatalinks->replaceChild($newSinkNode,$oldSinkNode);

			# d.-Update DataLinkSink with the new node:
			$parentDatalinks->appendChild($cloneDatalinks);
#			print("### cloneDatalinksSOURCE: ",(($cloneDatalinks->getChildrenByTagName("source"))[0])->textContent,"\n");
#			print("### cloneDatalinksSINK: ",(($cloneDatalinks->getChildrenByTagName("sink"))[0])->textContent,"\n");

			########################
			# SEE: http://search.cpan.org/~shlomif/XML-LibXML-2.0107/lib/XML/LibXML/Node.pod
			#  $newnode =$node->cloneNode(1);
			#  $oldnode = $node->replaceChild( $newNode, $oldNode );
			#  $node->replaceNode($newNode);
			#  $childnode = $node->appendChild( $childnode );
			#  $childnode = $node->addChild( $childnode );
			# ------------> For each iteration in the loop, I must create/add/replace one datalink.
		    } # end-foreach service datalink Source (service outputs)
		} # end-foreach service datalink Sink (service inputs)

		# To remove old datalink, in next two loops, with processor=<removed shim>
		@datalinkSinkList = $root->findnodes($queryXPathSink);
		foreach $datalinkSink (@datalinkSinkList){
		    print("Input removed.\n");
#		    print("### SOURCE: ",(($datalinkSink->getChildrenByTagName("source"))[0])->textContent,"\n");
#		    print("### SINK: ",(($datalinkSink->getChildrenByTagName("sink"))[0])->textContent,"\n");

		    $parentDatalinks=($datalinkSink->parentNode);
		    $parentDatalinks->removeChild($datalinkSink);
		} # end-foreach service datalink Sink (service inputs)		
		@datalinkSourceList = $root->findnodes($queryXPathSource);
		foreach $datalinkSource (@datalinkSourceList){
		    print("Output removed.\n");
#		    print("### SOURCE: ",(($datalinkSource->getChildrenByTagName("source"))[0])->textContent,"\n");
#		    print("### SINK: ",(($datalinkSource->getChildrenByTagName("sink"))[0])->textContent,"\n");
		    $parentDatalinks=($datalinkSource->parentNode);
		    $parentDatalinks->removeChild($datalinkSource);
		} # end-foreach service datalink Source (service outputs)
	    } # end-if service without inputs.
	   
	    # CONDITIONS
	    # To propagate associated conditions
	    $queryXPathConditionTarget='//ns:workflow/ns:dataflow/ns:conditions/ns:condition[@target = "'.$servName.'"]';
	    $queryXPathConditionControl='//ns:workflow/ns:dataflow/ns:conditions/ns:condition[@control = "'.$servName.'"]';
	    @conditionTargetList = $root->findnodes($queryXPathConditionTarget);
	    foreach $targetCondition (@conditionTargetList){
		@conditionControlList = $root->findnodes($queryXPathConditionControl);
		foreach $controlCondition (@conditionControlList){
		    # a.-Get a copy of the complete control condition node
		    $cloneCondition = $controlCondition->cloneNode(1);
		    # b.-Modify target service of the condition
		    $cloneCondition->setAttribute("control",$targetCondition->getAttribute("control"));
		    # c.-Update Conditions with the new condition (at the end, old condition associated with the removed server would be deleted).
		    $parent=($controlCondition->parentNode);
		    $parent->appendChild($cloneCondition);
#		    print("### New condition: ",$cloneCondition->textContent,"\n");
		} # end-foreach condition where CONTROL is current removed service
	    } # end-foreach condition where TARGET is current removed service

	    # To remove old conditions, in next two loops, with target or control=<removed shim>
	    @conditionTargetList = $root->findnodes($queryXPathConditionTarget);
	    foreach $targetCondition (@conditionTargetList){
#		print("### Condition removed (control-->target) ",$targetCondition->getAttribute("control"),"-->",$targetCondition->getAttribute("target"),"\n");
		$parent=($targetCondition->parentNode);
		$parent->removeChild($targetCondition);		
	    } # end-foreach condition where TARGET is current removed service
	    @conditionControlList = $root->findnodes($queryXPathConditionControl);
	    foreach $controlCondition (@conditionControlList){
#		print("### Condition removed (control-->target) ",$controlCondition->getAttribute("control"),"-->",$controlCondition->getAttribute("target"),"\n");
		$parent=($controlCondition->parentNode);
		$parent->removeChild($controlCondition);
	    } # end-foreach condition where CONTROL is current removed service

	} # end-if is not Removed
	else{
	    print("service type: $servType\n");
	}
	# In t2flow format, the services inside a nested workflow are already removed with the previous loop.
	$count=$count+1;
    } # end-foreach services
}else{
    print("ERROR: The file extension must be .xml for Taverna 1 workflows or .t2flow for Taverna 2 workflows!!!\n");
} # end-if SCUFL/T2FLOW format

# Write the file, with less nodes.
#XML::LibXML::Document [http://search.cpan.org/~shlomif/XML-LibXML-2.0107/lib/XML/LibXML/Document.pod]
$doc->toFile($fileOut,1); # It removes a blank before closing a tag, from ' />' with '/>'



