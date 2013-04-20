<?php
	$q = urlencode($_GET['q']);
	$url = "https://ajax.googleapis.com/ajax/services/search/news?" .
	       "v=1.0&q=" . $q;

	// sendRequest
	// note how referer is set manually
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_REFERER, "http://localhost");
	$body = curl_exec($ch);
	curl_close($ch);
	echo $body;
	// now have some fun with the results...