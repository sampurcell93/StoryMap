<?php

$string_to_analyze = $_GET['content'];

class CalaisPHPIf {
	
	var $apiKey 		= "c3wjfrkfmrsft3r5wgxm5skr";
	var $url 			= "http://api.opencalais.com/enlighten/rest/";
	var $paramsXML 		= "";
	var $contentType 	= "text/html";

	function CalaisPHPIf($apiKey = false) {
		
		if ($apiKey !== false)
		{
			$this->apiKey = $apiKey;
		}

		$this->paramsXML = $this->buildParamsXML();
	}

	/**
	 * Call the OpenCalais Enlighten Web Service and return the raw results
	 * 
	 */
	function callEnlighten($content) {

		if (!is_string($content) || strlen($content) == 0)
		{
			return "Non-empty content is required";
		}
	
		$data = "licenseID=" . urlencode($this->apiKey);
		$data .= "&paramsXML=" . urlencode($this->paramsXML);
		$data .= "&content=" . urlencode($content); 
		
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $this->url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($ch, CURLOPT_HEADER, 0);
		curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
		curl_setopt($ch, CURLOPT_POST, 1);
		$response = curl_exec($ch);
		curl_close($ch);

		if ($response === false || (strpos($response, "<Exception>") !== false)) {
			return "Enlighten ERROR: ".$response;
		}
		
		return $response;
	}

	function buildParamsXML() {

		$ret = "<c:params xmlns:c=\"http://s.opencalais.com/1/pred/\" " . 
			"xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"> " .
			"<c:processingDirectives c:contentType=\"".$this->contentType . "\" " .
			"c:outputFormat=\"application/json\"></c:processingDirectives> " .
			"<c:userDirectives c:allowDistribution=\"false\" " .
			"c:allowSearch=\"false\" c:externalID=\" \" " .
			"c:submitter=\"Story Map\"></c:userDirectives> " .
			"<c:externalMetadata><rdf:Description><c:caller>Story Map</c:caller></rdf:Description></c:externalMetadata></c:params>";
		
		return $ret;
	}
	
	function setContentType($contentType) {
		$this->contentType = $contentType;
		$this->paramsXML = $this->buildParamsXML();
	}
	
	function getContentType() {
		return $this->contentType;
	}
}

	$c = new CalaisPHPIf();
	$s = $c->callEnlighten($string_to_analyze);
	$a = json_decode($s);
	// unset($a->doc->meta);
	// unset($a->doc->info->id);
	// unset($a->doc->info->docId);
	// unset($a->doc->info->externalMetadata);
	$s = json_encode($a);
	echo utf8_encode($s);
	// echo '{"yolo":"sam"}';
?>
