<?php

    require("OAuth.php");
     
    $cc_key  = "dj0yJmk9RHp0ckM1NnRMUmk1JmQ9WVdrOVdUbHdOMkZLTTJVbWNHbzlNakV5TXpReE1EazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xMg--";
    $cc_secret = "626da2d06d0b80dbd90799715961dce4e13b8ba1";
    $url = "http://yboss.yahooapis.com/ysearch/news";
    $args = array();
    $args["q"] = urlencode($_GET['q']);
    $args["start"] = urlencode($_GET['start']);
    $args['sort'] = 'date';
    $args['age'] = '1000d';
    $args["format"] = "json";
     
    $consumer = new OAuthConsumer($cc_key, $cc_secret);
    $request = OAuthRequest::from_consumer_and_token($consumer, NULL,"GET", $url, $args);
    $request->sign_request(new OAuthSignatureMethod_HMAC_SHA1(), $consumer, NULL);
    $url = sprintf("%s?%s", $url, OAuthUtil::build_http_query($args));
    $ch = curl_init();
    $headers = array($request->to_header());
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
    $rsp = curl_exec($ch);
    echo $rsp;
?>