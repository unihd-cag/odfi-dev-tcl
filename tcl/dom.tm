package provide odfi::dom 1.0.0
package require odfi::common
package require dom


## This package provides some shortcut methods to manipulate XML data with TCL
namespace eval odfi::dom {
    
    variable namespaceContext {}
    
    
    #### Reading the file at path and try to parse an XML document from it
    proc buildDocumentFromFile filePath {
        
        ## Open File
        set fhandle [open $filePath "r+"]
        
        ## Read document
        set doc [::dom::DOMImplementation parse [read $fhandle]]
        
        ## Close file
        close $fhandle
        
        ## Return
        return $doc
        
        
    }
    
    #### Returns the local name of a node
    #### @return string
    proc getLocalName node {
        
        return [::dom::node cget $node -nodeName]
        
    }
    
    ## @return 1 if the attribute id present, 0 otherwise
    proc hasAttribute {node attributeName} {
            
        if {[getAttribute $node $attributeName]==""} {
            return 0
        } else {
            return 1
        }  
           
    }
    
    #### Returns the named attribute for the node
    proc getAttribute {node attributeName} {
            
        return [::dom::element getAttribute $node $attributeName]
        
    }
    
    #### Sets an attribute on a node
    proc setAttribute {node attributeName attributeValue} {
                
        return [::dom::element setAttribute $node $attributeName $attributeValue]
            
    }
    
    #### @return true if the node is the document, false if not
    proc isDocument node {
        
        if {[::dom::node cget $node -nodeType]=="document"} {
            return true
        }

        
        return false
    }
	
	proc addElementNS {parentNode ns name} {
		
		## Create
		set newNode [::dom::document createElementNS $parentNode $ns $name]
		
		return $newNode
		
	}
    
    #### Set text node of the provided node
    proc setNodeText {node text} {
        
        ## Is there already a text node?
        if {[::dom::node hasChildNodes $node]==1} {
            
            ::dom::node configure [::dom::node cget $node -firstChild] -nodeValue $text
            
        } else {
            set textNode [::dom::document createTextNode $node $text]
        }
    }
    
    ### Returns the Text content of the node
    proc getNodeText {node} {
        
        return [::dom::node stringValue $node]
        
    }
    
    ### Serialize the document to an indented UTF-8 string
    proc toIndentedString {node {encoding "UTF-8"}} {
        
        ::dom::DOMImplementation serialize $node -method xml -indent true -encoding $encoding
        
    }
    
    
    #### Register in a namespace list the prefix+namespace associations to be used for xpath resolution
    proc xpathRegisterNamespace {prefix ns} {
        
        lappend odfi::dom::namespaceContext $prefix $ns
        
    }
    
    ####
    proc xpathMatches {node xpath} {
        
        ## Execute expath
        set result [::dom::DOMImplementation selectNode $node $xpath -namespaces $odfi::dom::namespaceContext]
        
        ## Get First result or return ""
        if {[llength $result]==0} {
            return false
        } else {
            return true
        }
    }
    
    
    ## Returns one result of the provided expression as a string
    ## Returns an empty string if nothing was found
    proc xpathGetAsSingleString {node xpath} {

        ## Execute expath
        set result [::dom::DOMImplementation selectNode $node $xpath -namespaces $odfi::dom::namespaceContext]
        
        ## Get First result or return ""
        if {[llength $result]==0} {
            return ""
        } else {
         
            return [::dom::node stringValue [lindex $result 0]]
            
        }
        
        
    }
    
    ## Returns the first found node, or false
    proc xpathGetNode {node xpath} {
        
        ## Get nodes
        set resultList [xpathGetNodes $node $xpath]
        
        ## Return result
        if {[llength $resultList]>0} {
            return [lindex $resultList 0]
        } else {
            return false
        }
        
    }
    
    ## Returns a list of found node, or an empty list if nothing found
    proc xpathGetNodes {node xpath} {
        
        return [::dom::DOMImplementation selectNode $node $xpath -namespaces $odfi::dom::namespaceContext]
        
    }
    
    
    
}