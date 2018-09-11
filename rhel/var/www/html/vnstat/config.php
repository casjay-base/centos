<?php
    error_reporting(E_ALL | E_NOTICE);
    $locale = 'en_US.UTF-8';
    $language = 'en';
    date_default_timezone_set("America/New_York");
    $iface_list = array('eth0');
    $iface_title['eth0'] = 'Ethernet';
    $vnstat_bin = '/usr/bin/vnstat';
    $data_dir = './dumps';
    $graph_format='svg';
    $byte_notation = null;
    define('GRAPH_FONT',dirname(__FILE__).'/VeraBd.ttf');
    define('SVG_FONT', 'Verdana');
    define('DEFAULT_COLORSCHEME', 'light');
    define('SVG_DEPTH_SCALING', 1);
?>
