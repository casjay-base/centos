<?php
    //
    error_reporting(E_ALL | E_NOTICE);
    $locale = 'en_US.UTF-8';
    $language = 'en';
    $iface_list = array('eth0');
    $iface_title['eth0'] = 'External';
    $vnstat_bin = '/usr/bin/vnstat';
    $data_dir = './dump';
    $graph_format='png';
    define('GRAPH_FONT',dirname(__FILE__).'/VeraBd.ttf');
    define('SVG_FONT',dirname(__FILE__).'/VeraBd.ttf');
    define('DEFAULT_COLORSCHEME', 'light');

?>
