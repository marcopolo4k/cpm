<?php
$con=mysqli_connect("localhost","user1_u1db1","alongpassword","user1_db1");
// Check connection
if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

$sql="CREATE TABLE IF NOT EXISTS t1 (
id INT,
col1 BLOB
);";

if (!mysqli_query($con,$sql))
  {
  die('Error: ' . mysqli_error($con));
  }
echo "1 table added";

$input_data=readfile("largefile.txt");

for ($x=0; $x<=5000; $x++)
{
        $sql="INSERT INTO t1 (id, col1)
        VALUES
        ('','$input_data')";

        if (!mysqli_query($con,$sql))
          {
          die('Error: ' . mysqli_error($con));
          }
        echo "1 record added";

        $sql="DELETE FROM t1";

        if (!mysqli_query($con,$sql))
          {
          die('Error: ' . mysqli_error($con));
          }
        echo "1 record deleted";
}

mysqli_close($con);
?>
