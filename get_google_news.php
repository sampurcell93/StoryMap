<?php
	$q = urlencode($_GET['q']);
	$start = urlencode(intval($_GET['start']));
	function pull($url) {
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($ch, CURLOPT_REFERER, "http://localhost");
		$body = curl_exec($ch);
		curl_close($ch);
 		return $body;
	}
	$body = pull( "https://ajax.googleapis.com/ajax/services/search/news?" . "v=1.0&rsz=8&start=" . $start . "&q=" . $q);
	echo $body;