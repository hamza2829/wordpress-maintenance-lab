<?php
$root = dirname(__DIR__, 2);
$_SERVER['HTTP_HOST'] = '127.0.0.1:8080';
$_SERVER['REQUEST_URI'] = '/';
$_SERVER['SERVER_NAME'] = '127.0.0.1';
$_SERVER['SERVER_PORT'] = '8080';
require $root . '/.runtime/wp-tests/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/template.php';
